import React, { useEffect, useState, useCallback, useRef } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { applyActionCode, onAuthStateChanged } from "firebase/auth";
import { auth } from "../../firebase";
import { Button, Spin } from "antd";
import "./RegisterCard.css";
import "./EmailVerificationPage.css";

const AuthActionPage = () => {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();

    const [status, setStatus] = useState("loading"); // loading, error (success → redirect)
    const [errorMessage, setErrorMessage] = useState("");
    const verifyStartedRef = useRef(false);

    const mode = searchParams.get("mode");
    const oobCode = searchParams.get("oobCode");

    const handleVerifyEmail = useCallback(
        async (code) => {
            try {
                await applyActionCode(auth, code);
                const unsubscribe = onAuthStateChanged(auth, async (user) => {
                    if (user) await user.reload();
                    unsubscribe();
                });
                navigate("/verify-email?verified=1", { replace: true });
            } catch (error) {
                console.error("Verification error:", error);
                setStatus("error");
                if (error.code === "auth/invalid-action-code") {
                    setErrorMessage("This link has already been used or has expired. Request a new verification email from the app.");
                } else {
                    setErrorMessage("Something went wrong while confirming your email. Please try again.");
                }
            }
        },
        [navigate]
    );

    useEffect(() => {
        if (!mode || !oobCode) {
            setStatus("error");
            setErrorMessage("This link is missing required information. Open the latest email from Vacanza or sign in to resend.");
            return;
        }

        if (mode === "verifyEmail") {
            if (verifyStartedRef.current) return;
            verifyStartedRef.current = true;
            handleVerifyEmail(oobCode);
        } else if (mode === "resetPassword") {
            setStatus("error");
            setErrorMessage("Password reset from this link is not set up yet. Use “Forgot password?” on the login page.");
        } else {
            setStatus("error");
            setErrorMessage("This type of link is not supported.");
        }
    }, [mode, oobCode, handleVerifyEmail]);

    if (status === "loading") {
        return (
            <div className="register-card verify-email-loading">
                <Spin size="large" />
                <p className="header-subtext" style={{ marginTop: 16, marginBottom: 0 }}>
                    Verifying your email…
                </p>
            </div>
        );
    }

    return (
        <div className="register-card">
            <div className="card-header">
                <h3>
                    Couldn&apos;t <span>confirm</span>
                </h3>
                <p className="header-subtext">{errorMessage}</p>
            </div>
            <div style={{ marginTop: 20 }}>
                <Button type="primary" size="large" block className="cta-button" onClick={() => navigate("/login")}>
                    Back to log in
                </Button>
            </div>
            <div className="login-redirect">
                Need an account?{" "}
                <span onClick={() => navigate("/register")} className="login-link">
                    Sign up
                </span>
            </div>
        </div>
    );
};

export default AuthActionPage;

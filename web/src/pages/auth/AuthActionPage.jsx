import React, { useEffect, useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { applyActionCode, onAuthStateChanged } from "firebase/auth";
import { auth } from "../../firebase";
import { Button, Spin, Result } from "antd";
import { CheckCircleFilled, CloseCircleFilled, LoadingOutlined } from "@ant-design/icons";
import "./AuthActionPage.css";

const AuthActionPage = () => {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();

    const [status, setStatus] = useState("loading"); // loading, success, error
    const [errorMessage, setErrorMessage] = useState("");

    const mode = searchParams.get("mode");
    const oobCode = searchParams.get("oobCode");

    useEffect(() => {
        if (!mode || !oobCode) {
            setStatus("error");
            setErrorMessage("Invalid link parameters.");
            return;
        }

        if (mode === "verifyEmail") {
            handleVerifyEmail(oobCode);
        } else if (mode === "resetPassword") {
            // Future extension point: resetPassword flow
            setStatus("error");
            setErrorMessage("Password reset flow is not implemented here yet.");
        } else {
            setStatus("error");
            setErrorMessage("Unsupported action mode.");
        }
    }, [mode, oobCode]);

    const handleVerifyEmail = async (code) => {
        try {
            await applyActionCode(auth, code);
            setStatus("success");

            // If user is already logged in, try to reload their profile
            const unsubscribe = onAuthStateChanged(auth, async (user) => {
                if (user) {
                    await user.reload();
                }
                unsubscribe();
            });

        } catch (error) {
            console.error("Verification error:", error);
            setStatus("error");
            if (error.code === "auth/invalid-action-code") {
                setErrorMessage("This verification link has already been used or has expired.");
            } else {
                setErrorMessage("An error occurred during email verification.");
            }
        }
    };

    return (
        <div className="action-page">
            <div className="action-card">
                {status === "loading" && (
                    <div className="action-loading">
                        <Spin indicator={<LoadingOutlined style={{ fontSize: 48, color: "#00acc1" }} spin />} />
                        <p className="action-text">Verifying your email...</p>
                    </div>
                )}

                {status === "success" && (
                    <div className="action-success">
                        <div className="action-icon-wrap success">
                            <CheckCircleFilled className="action-icon success" />
                        </div>
                        <h1 className="action-title">Email Verified</h1>
                        <p className="action-description">
                            Your email has been successfully verified.
                            <br />
                            You're all set to explore <span className="action-brand">Vacanza</span>!
                        </p>
                        <Button
                            type="primary"
                            size="large"
                            block
                            onClick={() => navigate("/verify-email?verified=1")}
                            className="action-btn success"
                        >
                            Continue
                        </Button>
                    </div>
                )}

                {status === "error" && (
                    <div className="action-error">
                        <div className="action-icon-wrap error">
                            <CloseCircleFilled className="action-icon error" />
                        </div>
                        <h1 className="action-title">Verification Failed</h1>
                        <p className="action-description">{errorMessage}</p>
                        <Button
                            type="default"
                            size="large"
                            block
                            onClick={() => navigate("/login")}
                            className="action-btn error"
                        >
                            Back to Login
                        </Button>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AuthActionPage;

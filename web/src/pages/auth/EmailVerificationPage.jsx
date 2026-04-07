import React, { useState, useEffect, useCallback } from "react";
import { Button, message, Spin } from "antd";
import { CheckCircleFilled } from "@ant-design/icons";
import { useNavigate, useSearchParams } from "react-router-dom";
import { auth } from "../../firebase";
import { sendEmailVerification, onAuthStateChanged, signOut } from "firebase/auth";
import "./RegisterCard.css";
import "./EmailVerificationPage.css";

/** After Firebase email link verification, redirect here with ?verified=1 so guests see success + Log in. */
const VERIFIED_QUERY = "verified";

const EmailVerificationPage = () => {
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();
    const verifiedFromLink = searchParams.get(VERIFIED_QUERY) === "1";

    const [resending, setResending] = useState(false);
    const [checking, setChecking] = useState(false);
    const [cooldown, setCooldown] = useState(0);
    const [showSuccess, setShowSuccess] = useState(false);
    const [guestVerified, setGuestVerified] = useState(false);
    const [authReady, setAuthReady] = useState(false);

    useEffect(() => {
        const unsub = onAuthStateChanged(auth, (user) => {
            setAuthReady(true);
            if (!user) {
                if (verifiedFromLink) {
                    setGuestVerified(true);
                } else {
                    navigate("/login", { replace: true });
                }
                return;
            }
            setGuestVerified(false);
            if (user.emailVerified) {
                navigate("/map", { replace: true });
            }
        });
        return () => unsub();
    }, [navigate, verifiedFromLink]);

    useEffect(() => {
        if (cooldown <= 0) return;
        const t = setTimeout(() => setCooldown((c) => c - 1), 1000);
        return () => clearTimeout(t);
    }, [cooldown]);

    const handleResend = useCallback(async () => {
        const user = auth.currentUser;
        if (!user) return;
        setResending(true);
        setShowSuccess(false);
        try {
            await sendEmailVerification(user);
            setShowSuccess(true);
            setCooldown(60);
        } catch (e) {
            if (e.code === "auth/too-many-requests") {
                message.warning("Too many attempts. Please wait a moment.");
                setCooldown(30);
            } else {
                message.error("Failed to send verification email.");
            }
        } finally {
            setResending(false);
        }
    }, []);

    useEffect(() => {
        if (cooldown === 0) setShowSuccess(false);
    }, [cooldown]);

    const handleCheckVerification = useCallback(async () => {
        setChecking(true);
        try {
            await auth.currentUser?.reload();
            const refreshed = auth.currentUser;
            if (refreshed?.emailVerified) {
                message.success("Email verified! Redirecting...");
                setTimeout(() => navigate("/map"), 800);
            } else {
                message.info("Email not yet verified. Please check your inbox.");
            }
        } catch {
            message.error("Could not check status.");
        } finally {
            setChecking(false);
        }
    }, [navigate]);

    const goToLogin = useCallback(async () => {
        try {
            if (auth.currentUser) await signOut(auth);
        } catch {
            /* ignore */
        }
        navigate("/login");
    }, [navigate]);

    if (!authReady) {
        return (
            <div className="register-card verify-email-loading">
                <Spin size="large" />
            </div>
        );
    }

    if (guestVerified) {
        return (
            <div className="register-card">
                <div className="card-header">
                    <h3>
                        Email <span>verified</span>
                    </h3>
                    <p className="header-subtext">Sign in with your email and password to continue your journey</p>
                </div>
                <div style={{ marginTop: 20 }}>
                    <Button type="primary" size="large" block className="cta-button" onClick={goToLogin}>
                        Log in
                    </Button>
                </div>
            </div>
        );
    }

    return (
        <div className="register-card">
            <div className="card-header">
                <h3>
                    Verify your <span>email</span>
                </h3>
                <p className="header-subtext">
                    We sent a confirmation link to your inbox. Open it to verify your address, then tap below.
                </p>
            </div>
            <div className="verify-email-actions" style={{ marginTop: 20 }}>
                <Button
                    type="primary"
                    size="large"
                    block
                    loading={checking}
                    onClick={handleCheckVerification}
                    className="cta-button"
                >
                    I&apos;ve verified
                </Button>
                <Button
                    block
                    size="large"
                    loading={resending}
                    disabled={cooldown > 0}
                    onClick={handleResend}
                    className="verify-email-secondary-btn"
                >
                    {cooldown > 0 ? `Resend in ${cooldown}s` : "Resend email"}
                </Button>
            </div>
            {showSuccess && (
                <div className="verify-email-inline-success">
                    <CheckCircleFilled className="verify-email-inline-success-icon" />
                    <span>Check your inbox for the link</span>
                </div>
            )}
            <div className="login-redirect">
                Different account?{" "}
                <span onClick={goToLogin} className="login-link">
                    Log in
                </span>
            </div>
        </div>
    );
};

export default EmailVerificationPage;

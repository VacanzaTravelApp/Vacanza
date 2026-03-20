import React, { useState, useEffect, useCallback } from "react";
import { Button, message } from "antd";
import { CheckCircleFilled } from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { auth } from "../../firebase";
import { sendEmailVerification, onAuthStateChanged } from "firebase/auth";
import "./EmailVerificationPage.css";

const EmailVerificationPage = () => {
    const navigate = useNavigate();
    const [resending, setResending] = useState(false);
    const [checking, setChecking] = useState(false);
    const [cooldown, setCooldown] = useState(0);

    // Redirect if not logged in or already verified
    useEffect(() => {
        const unsub = onAuthStateChanged(auth, (user) => {
            if (!user) {
                navigate("/login");
            } else if (user.emailVerified) {
                navigate("/map");
            }
        });
        return () => unsub();
    }, [navigate]);

    // Cooldown timer
    useEffect(() => {
        if (cooldown <= 0) return;
        const t = setTimeout(() => setCooldown((c) => c - 1), 1000);
        return () => clearTimeout(t);
    }, [cooldown]);

    const [showSuccess, setShowSuccess] = useState(false);

    const handleResend = useCallback(async () => {
        const user = auth.currentUser;
        if (!user) return;
        setResending(true);
        setShowSuccess(false);
        try {
            await sendEmailVerification(user);
            setShowSuccess(true);
            setCooldown(60); // 60 second cooldown
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

    // Clear success message when cooldown is almost over or on manual check
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

    return (
        <div className="verify-page">
            <div className="verify-card">
                {/* Email Icon */}
                <div className="verify-icon-wrap">
                    <div className="verify-icon">
                        <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                            <rect x="4" y="10" width="40" height="28" rx="4" stroke="#00acc1" strokeWidth="2.5" fill="none" />
                            <path d="M4 14l20 13 20-13" stroke="#00acc1" strokeWidth="2.5" fill="none" strokeLinecap="round" strokeLinejoin="round" />
                            <circle cx="38" cy="14" r="7" fill="#4caf50" />
                            <path d="M34.5 14l2.5 2.5 4-4" stroke="#fff" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                    </div>
                </div>

                {/* Title */}
                <h1 className="verify-title">Verify your email</h1>

                {/* Description */}
                <p className="verify-description">
                    We sent a verification link to your email address.
                    <br />
                    Please verify your email to continue to <span className="verify-brand">Vacanza</span>.
                </p>

                {/* I Verified Button */}
                <Button
                    type="primary"
                    block
                    size="large"
                    loading={checking}
                    onClick={handleCheckVerification}
                    className="verify-check-btn"
                >
                    I verified
                </Button>

                {/* Resend Button */}
                <Button
                    block
                    size="large"
                    loading={resending}
                    disabled={cooldown > 0}
                    onClick={handleResend}
                    className="verify-second-btn"
                >
                    {cooldown > 0 ? `Resend in ${cooldown}s` : "Resend verification email"}
                </Button>

                {/* Inline Success Informative State */}
                {showSuccess && (
                    <div className="verify-inline-success">
                        <CheckCircleFilled className="success-inline-icon" />
                        <span>Check your inbox for the link</span>
                    </div>
                )}
            </div>
        </div>
    );
};

export default EmailVerificationPage;

import React, { useEffect, useState, useCallback, useRef } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { applyActionCode, confirmPasswordReset, verifyPasswordResetCode, onAuthStateChanged } from "firebase/auth";
import { auth } from "../../firebase";
import { Button, Input, Form, Spin } from "antd";
import { toast } from "../../components/toast/toast";
import { LockOutlined, CheckCircleFilled } from "@ant-design/icons";
import "./RegisterCard.css";
import "./EmailVerificationPage.css";

const AuthActionPage = () => {
    const [searchParams] = useSearchParams();
    const navigate = useNavigate();

    const [status, setStatus] = useState("loading"); // loading, resetPassword, resetSuccess, error
    const [errorMessage, setErrorMessage] = useState("");
    const [resetEmail, setResetEmail] = useState("");
    const [resetting, setResetting] = useState(false);
    const [form] = Form.useForm();
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

    const handleVerifyResetCode = useCallback(async (code) => {
        if (import.meta.env.DEV && code.startsWith("test")) {
            setResetEmail("test@vacanza.app");
            setStatus("resetPassword");
            return;
        }
        try {
            const email = await verifyPasswordResetCode(auth, code);
            setResetEmail(email);
            setStatus("resetPassword");
        } catch (error) {
            console.error("Reset code verification error:", error);
            setStatus("error");
            if (error.code === "auth/invalid-action-code") {
                setErrorMessage("This password reset link has expired or has already been used. Please request a new one from the login page.");
            } else {
                setErrorMessage("Something went wrong verifying this reset link. Please try again.");
            }
        }
    }, []);

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
            if (verifyStartedRef.current) return;
            verifyStartedRef.current = true;
            handleVerifyResetCode(oobCode);
        } else {
            setStatus("error");
            setErrorMessage("This type of link is not supported.");
        }
    }, [mode, oobCode, handleVerifyEmail, handleVerifyResetCode]);

    const handleResetPassword = async (values) => {
        if (values.password !== values.confirmPassword) {
            form.setFields([{ name: "confirmPassword", errors: ["Passwords do not match."] }]);
            return;
        }
        setResetting(true);
        try {
            if (import.meta.env.DEV && oobCode.startsWith("test")) {
                await new Promise(r => setTimeout(r, 800));
            } else {
                await confirmPasswordReset(auth, oobCode, values.password);
            }
            setStatus("resetSuccess");
        } catch (error) {
            console.error("Password reset error:", error);
            if (error.code === "auth/weak-password") {
                form.setFields([{ name: "password", errors: ["Password is too weak. Use at least 6 characters."] }]);
            } else if (error.code === "auth/invalid-action-code") {
                setStatus("error");
                setErrorMessage("This reset link has expired. Please request a new one.");
            } else {
                toast.error("Something went wrong. Please try again.");
            }
        } finally {
            setResetting(false);
        }
    };

    // Loading
    if (status === "loading") {
        return (
            <div className="register-card verify-email-loading">
                <Spin size="large" />
                <p className="header-subtext" style={{ marginTop: 16, marginBottom: 0 }}>
                    Verifying your link…
                </p>
            </div>
        );
    }

    // Reset Password Form
    if (status === "resetPassword") {
        return (
            <div className="register-card">
                <div className="card-header">
                    <h3>
                        Reset <span>password</span>
                    </h3>
                    <p className="header-subtext">
                        Enter a new password for {resetEmail}
                    </p>
                </div>
                <Form form={form} layout="vertical" onFinish={handleResetPassword}>
                    <Form.Item
                        name="password"
                        label="New Password"
                        rules={[
                            { required: true, message: "Please enter your new password." },
                            { min: 6, message: "Password must be at least 6 characters." }
                        ]}
                    >
                        <Input.Password
                            prefix={<LockOutlined />}
                            placeholder="New password"
                            size="large"
                        />
                    </Form.Item>
                    <Form.Item
                        name="confirmPassword"
                        label="Confirm Password"
                        rules={[
                            { required: true, message: "Please confirm your password." },
                        ]}
                    >
                        <Input.Password
                            prefix={<LockOutlined />}
                            placeholder="Confirm new password"
                            size="large"
                        />
                    </Form.Item>
                    <div style={{ marginTop: 8 }}>
                        <Button
                            type="primary"
                            size="large"
                            block
                            className="cta-button"
                            htmlType="submit"
                            loading={resetting}
                        >
                            Reset Password
                        </Button>
                    </div>
                </Form>
                <div className="login-redirect">
                    Remember your password?
                    <span onClick={() => navigate("/login")} className="login-link">
                        Log in
                    </span>
                </div>
            </div>
        );
    }

    // Reset Success
    if (status === "resetSuccess") {
        return (
            <div className="register-card">
                <div className="card-header">
                    <div style={{ marginBottom: 12 }}>
                        <CheckCircleFilled style={{ fontSize: 48, color: "var(--vivid-green, #2DD4A8)" }} />
                    </div>
                    <h3>
                        Password <span>updated</span>
                    </h3>
                    <p className="header-subtext">
                        Your password has been reset successfully. You can now log in with your new password.
                    </p>
                </div>
                <div style={{ marginTop: 20 }}>
                    <Button type="primary" size="large" block className="cta-button" onClick={() => navigate("/login", { replace: true })}>
                        Back to log in
                    </Button>
                </div>
            </div>
        );
    }

    // Error
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

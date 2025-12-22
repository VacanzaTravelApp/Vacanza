// src/pages/auth/LoginCard.jsx

import React, { useState } from "react";
import { Form, Input, Button, message } from "antd";
import { LockOutlined, MailOutlined, SendOutlined } from "@ant-design/icons";
import "./RegisterCard.css";
import { useNavigate } from "react-router-dom";

//Firebase
import { signInWithEmailAndPassword, sendPasswordResetEmail } from "firebase/auth";
import { auth } from "../../firebase";

// API
import { authApi } from "../../api/authApi";

const LoginCard = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);

  const onFinish = async ({ email, password }) => {
    setLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
  console.log("Firebase login successful.");
      try {
        await authApi.login();
        console.log("Backend sync successful.");
      // eslint-disable-next-line no-unused-vars
      } catch (syncError) {
        console.warn("Backend sync skipped: Server returned HTML, but we are logged in via Firebase.");
      }
   message.success("Logged in successfully!");
      navigate("/map");
    } catch (error) {
      console.error("Firebase login error:", error);

      let msg = "Login failed. Please try again.";
      if (error?.code === "auth/invalid-email") msg = "Please enter a valid email address.";
      if (error?.code === "auth/user-not-found") msg = "No user found with this email.";
      if (error?.code === "auth/invalid-credential" || error?.code === "auth/wrong-password")
        msg = "Incorrect email or password.";

      message.error(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    const userEmail = window.prompt("Enter your email to reset your password:");
    if (!userEmail) return;

    try {
      await sendPasswordResetEmail(auth, userEmail);
      message.success("Password reset email sent. Please check your inbox.");
    } catch (error) {
      console.error("Reset password error:", error);
      message.error("Could not send reset email. Please check the email address.");
    }
  };

  return (
    <div className="register-card">
      <div className="card-header">
        <span className="vacanza-logo">
          <SendOutlined className="logo-icon" />
          Vacanza
        </span>
        <h3>Welcome Back</h3>
        <p className="header-subtext">Sign in to continue</p>
      </div>

      <Form name="login" onFinish={onFinish} layout="vertical" className="auth-form">
        <Form.Item
          name="email"
          rules={[
            { type: "email", message: "Please enter a valid email address!" },
            { required: true, message: "Please enter your email!" },
          ]}
        >
          <Input prefix={<MailOutlined />} placeholder="Email address" size="large" autoComplete="email" />
        </Form.Item>

        <Form.Item name="password" rules={[{ required: true, message: "Please enter your password!" }]}>
          <Input.Password
            prefix={<LockOutlined />}
            placeholder="Password"
            size="large"
            autoComplete="current-password"
          />
        </Form.Item>

        <div className="login-options-row">
          <span className="remember-me-placeholder" />
          <span onClick={handleForgotPassword} className="forgot-password-link">
            Forgot Password?
          </span>
        </div>

        <Form.Item style={{ marginTop: 20 }}>
          <Button type="primary" htmlType="submit" className="cta-button" size="large" loading={loading}>
            Log In
          </Button>
        </Form.Item>
      </Form>

      <div className="login-redirect">
        Don&apos;t have an account?{" "}
        <span onClick={() => navigate("/register")} className="login-link">
          Sign Up
        </span>
      </div>
    </div>
  );
};

export default LoginCard;

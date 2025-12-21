// src/pages/auth/LoginCard.jsx
import React, { useState } from "react";
import { Form, Input, Button, message } from "antd";
import { LockOutlined, MailOutlined, SendOutlined } from "@ant-design/icons";
import "./RegisterCard.css";
import { useNavigate } from "react-router-dom";

import { signInWithEmailAndPassword, sendPasswordResetEmail } from "firebase/auth";
import { auth } from "../../firebase";
import { authApi } from "../../api/authApi";

export default function LoginCard() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [form] = Form.useForm();

  const onFinish = async ({ email, password }) => {
    setLoading(true);

    try {
      // 1) Firebase login
      await signInWithEmailAndPassword(auth, email, password);

      // 2) Backend sync (GET /auth/login)
      await authApi.login();

      message.success("Login successful. Redirecting to the map...");
      navigate("/map");
    } catch (error) {
      console.error("Login error:", error);

      let errorMessage = "Login failed. Please try again.";
      if (error?.code === "auth/user-not-found" || error?.code === "auth/wrong-password") {
        errorMessage = "Invalid email or password.";
      }
      if (error?.response?.status === 401) {
        errorMessage = "Session is not valid. Please login again.";
      }

      message.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    const email = form.getFieldValue("email");

    if (!email) {
      message.info("Please enter your email first.");
      return;
    }

    try {
      await sendPasswordResetEmail(auth, email);
      message.success("Password reset email sent. Please check your inbox.");
    } catch (err) {
      console.error("Reset password error:", err);
      message.error("Could not send reset email. Please check the email address.");
    }
  };

  return (
    <div className="register-card">
      <div className="card-header">
        <span className="vacanza-logo">
          <SendOutlined className="logo-icon" /> Vacanza
        </span>
        <h3>Welcome Back</h3>
        <p className="header-subtext">Sign in to continue your journey</p>
      </div>

      <Form
        form={form}
        name="login"
        onFinish={onFinish}
        layout="vertical"
        className="auth-form"
      >
        <Form.Item
          name="email"
          rules={[
            { type: "email", message: "Please enter a valid email address." },
            { required: true, message: "Please enter your email." },
          ]}
        >
          <Input prefix={<MailOutlined />} placeholder="Email" size="large" autoComplete="email" />
        </Form.Item>

        <Form.Item
          name="password"
          rules={[{ required: true, message: "Please enter your password." }]}
        >
          <Input.Password
            prefix={<LockOutlined />}
            placeholder="Password"
            size="large"
            autoComplete="current-password"
          />
        </Form.Item>

        <div className="login-options-row">
          <span />
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
        Don't have an account?{" "}
        <span onClick={() => navigate("/register")} className="login-link">
          Sign Up
        </span>
      </div>
    </div>
  );
}

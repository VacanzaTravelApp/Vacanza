// src/pages/auth/LoginCard.jsx

import React, { useState } from "react";
import { Form, Input, Button, message, Modal } from "antd";
import { LockOutlined, MailOutlined } from "@ant-design/icons";
import { MdFlightTakeoff } from 'react-icons/md';
import "./RegisterCard.css";
import { useNavigate } from "react-router-dom";

//Firebase
import { signInWithEmailAndPassword, sendPasswordResetEmail } from "firebase/auth";
import { auth } from "../../firebase";

// API
import { authApi } from "../../api/userApi";

const LoginCard = () => {
  const navigate = useNavigate();
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [isResetModalOpen, setIsResetModalOpen] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [resetLoading, setResetLoading] = useState(false);

  const onFinish = async ({ email, password }) => {
    setLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email, password);
      console.log("Firebase login successful.");
      try {
        await authApi.login();
        console.log("Backend sync successful.");
      } catch (syncError) {
        // If it's a real auth failure (401/403), re-throw to outer catch
        if (syncError.response?.status === 401 || syncError.response?.status === 403) {
          throw syncError;
        }
        console.warn("Backend sync skipped:", syncError.message);
      }
      navigate("/map");
    } catch (error) {
      console.error("Firebase login error:", error);

      if (error?.code === "auth/invalid-email") {
        form.setFields([
          {
            name: 'email',
            errors: ['Please enter a valid email address.'],
          },
        ]);
      } else if (error?.code === "auth/user-not-found" || error?.code === "auth/invalid-credential" || error?.code === "auth/wrong-password") {
        form.setFields([
          {
            name: 'email',
            errors: [' '],
          },
          {
            name: 'password',
            errors: ['We couldn\'t find an account with that email or password.'],
          },
        ]);
      } else if (error?.code === "auth/too-many-requests") {
        message.error("Too many failed attempts. Please try again later or reset your password.");
      } else {
        message.error(error.friendlyMessage || "Login failed. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordReset = async () => {
    if (!resetEmail) {
      message.warning("Please enter your email address.");
      return;
    }

    setResetLoading(true);
    try {
      await sendPasswordResetEmail(auth, resetEmail);
      message.success("A password reset link has been sent to your email!");
      setIsResetModalOpen(false);
      setResetEmail("");
    } catch (error) {
      console.error("Reset password error:", error);
      let msg = "Could not send reset email. Please try again.";
      if (error?.code === "auth/invalid-email") msg = "Please enter a valid email address.";
      if (error?.code === "auth/user-not-found") msg = "No account found with this email.";
      message.error(msg);
    } finally {
      setResetLoading(false);
    }
  };

  return (
    <div className="register-card">
      <div className="card-header">
        <span className="vacanza-logo">
          <MdFlightTakeoff className="logo-icon" />
          Vacanza
        </span>
        <h3>Welcome Back to <span style={{ color: '#3da8c8' }}>Vacanza</span></h3>
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
          <span onClick={() => setIsResetModalOpen(true)} className="forgot-password-link">
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

      <Modal
        title="Reset Password"
        open={isResetModalOpen}
        onOk={handlePasswordReset}
        onCancel={() => setIsResetModalOpen(false)}
        confirmLoading={resetLoading}
        okText="Send Reset Link"
        cancelText="Cancel"
      >
        <div style={{ marginBottom: 16 }}>
          Enter the email address associated with your account and we&apos;ll send you a link to reset your password.
        </div>
        <Input
          prefix={<MailOutlined />}
          placeholder="Email address"
          size="large"
          value={resetEmail}
          onChange={(e) => setResetEmail(e.target.value)}
        />
      </Modal>
    </div>
  );
};

export default LoginCard;

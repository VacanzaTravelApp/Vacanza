import React, { useState } from "react";
import { Form, Input, Button, Checkbox, Row, Col, message } from "antd";
import {
  UserOutlined,
  LockOutlined,
  MailOutlined,
  SendOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from "@ant-design/icons";
import "./RegisterCard.css";
import { useNavigate } from "react-router-dom";

import { createUserWithEmailAndPassword, updateProfile } from "firebase/auth";
import { auth } from "../../firebase";
import { authApi } from "../../api/authApi";

const PasswordChecks = ({ password }) => {
  const checks = [
    { text: "8+ characters", valid: password && password.length >= 8 },
    { text: "1+ uppercase", valid: /[A-Z]/.test(password || "") },
    { text: "1+ lowercase", valid: /[a-z]/.test(password || "") },
    { text: "1 number", valid: /[0-9]/.test(password || "") },
    { text: "1 special char", valid: /[^A-Za-z0-9]/.test(password || "") },
  ];

  if (!password) return null;

  return (
    <Row gutter={[10, 5]} className="password-checks-container">
      {checks.map((check) => (
        <Col span={12} key={check.text}>
          <div className={`password-check-item ${check.valid ? "valid" : "invalid"}`}>
            <span className="check-indicator" style={{ marginRight: 8 }}>
              {check.valid ? (
                <CheckCircleOutlined style={{ color: "#52c41a" }} />
              ) : (
                <CloseCircleOutlined style={{ color: "#bfbfbf" }} />
              )}
            </span>
            {check.text}
          </div>
        </Col>
      ))}
    </Row>
  );
};

const RegisterCard = () => {
  const navigate = useNavigate();
  const [form] = Form.useForm();
  const password = Form.useWatch("password", form);
  const [loading, setLoading] = useState(false);

  const onFinish = async (values) => {
    setLoading(true);

    const {
      email,
      password,
      firstName,
      middleName,
      lastName,
      preferredName,
    } = values;

    try {
      // 1) Firebase register
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);

      // Optional: set displayName in Firebase (for UI)
      const displayName = preferredName?.trim()
        ? preferredName.trim()
        : `${firstName} ${lastName}`.trim();

      await updateProfile(userCredential.user, { displayName });

      // 2) Backend profile sync: POST /auth/register (Bearer token is auto attached by http.js)
      await authApi.register({
        firstName,
        middleName: middleName || null,
        lastName,
        preferredName: preferredName || null,
      });

      message.success("Registration successful! Redirecting to the map...");
      navigate("/map");
    } catch (error) {
      console.error("Register error:", error);

      // Firebase errors
      const code = error?.code;

      let errorMessage = "Registration failed. Please try again.";
      if (code === "auth/email-already-in-use") errorMessage = "This email is already in use.";
      if (code === "auth/invalid-email") errorMessage = "Invalid email address.";
      if (code === "auth/weak-password") errorMessage = "Password is too weak.";

      // Backend errors (axios)
      if (error?.response?.status === 401) {
        errorMessage = "Token validation failed. Please log in again.";
      }
      if (error?.response?.data?.message) {
        // if backend sends message
        errorMessage = error.response.data.message;
      }

      message.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="register-card">
      <div className="card-header">
        <span className="vacanza-logo">
          <SendOutlined className="logo-icon" /> Vacanza
        </span>
        <h3>Start Your Adventure</h3>
        <p className="header-subtext">Create an account to continue</p>
      </div>

      <Form
        form={form}
        name="register"
        onFinish={onFinish}
        scrollToFirstError
        layout="vertical"
        className="auth-form"
      >
        <Row gutter={12}>
          <Col span={12}>
            <Form.Item
              name="firstName"
              rules={[{ required: true, message: "Please enter your first name." }]}
            >
              <Input prefix={<UserOutlined />} placeholder="First Name" size="large" />
            </Form.Item>
          </Col>

          <Col span={12}>
            <Form.Item name="middleName">
              <Input prefix={<UserOutlined />} placeholder="Middle Name (Optional)" size="large" />
            </Form.Item>
          </Col>
        </Row>

        <Form.Item
          name="lastName"
          rules={[{ required: true, message: "Please enter your last name." }]}
        >
          <Input prefix={<UserOutlined />} placeholder="Last Name" size="large" />
        </Form.Item>

        <Form.Item name="preferredName">
          <Input prefix={<UserOutlined />} placeholder="Preferred Name (Optional)" size="large" />
        </Form.Item>

        <Form.Item
          name="email"
          rules={[
            { type: "email", message: "Invalid email format." },
            { required: true, message: "Please enter your email." },
          ]}
        >
          <Input prefix={<MailOutlined />} placeholder="Email" size="large" autoComplete="email" />
        </Form.Item>

        <Form.Item
          name="password"
          rules={[{ required: true, message: "Please enter your password." }]}
          hasFeedback
        >
          <Input.Password
            prefix={<LockOutlined />}
            placeholder="Password"
            size="large"
            autoComplete="new-password"
          />
        </Form.Item>

        <PasswordChecks password={password} />

        <Form.Item
          name="confirmPassword"
          dependencies={["password"]}
          hasFeedback
          rules={[
            { required: true, message: "Please confirm your password." },
            ({ getFieldValue }) => ({
              validator(_, value) {
                if (!value || getFieldValue("password") === value) return Promise.resolve();
                return Promise.reject(new Error("Passwords do not match."));
              },
            }),
          ]}
        >
          <Input.Password
            prefix={<LockOutlined />}
            placeholder="Confirm Password"
            size="large"
            autoComplete="new-password"
          />
        </Form.Item>

        <Form.Item
          name="agreedToTerms"
          valuePropName="checked"
          rules={[
            {
              validator: (_, value) =>
                value ? Promise.resolve() : Promise.reject(new Error("You must accept the terms.")),
            },
          ]}
        >
          <Checkbox>
            I agree to the <a href="#">Terms & Conditions</a> and <a href="#">Privacy Policy</a>
          </Checkbox>
        </Form.Item>

        <Form.Item>
          <Button type="primary" htmlType="submit" className="cta-button" size="large" loading={loading}>
            Create Account
          </Button>
        </Form.Item>
      </Form>

      <div className="login-redirect">
        Already have an account?{" "}
        <span onClick={() => navigate("/login")} className="login-link">
          Log In
        </span>
      </div>
    </div>
  );
};

export default RegisterCard;
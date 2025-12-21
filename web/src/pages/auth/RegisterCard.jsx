// src/pages/auth/RegisterCard.jsx

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

// ✅ Firebase
import { createUserWithEmailAndPassword, updateProfile } from "firebase/auth";
import { auth } from "../../firebase";

// PasswordChecks component (same behavior, clean)
const PasswordChecks = ({ password }) => {
  const checks = [
    { text: "8+ characters", valid: password?.length >= 8 },
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

    const { email, password, firstName, lastName } = values;

    try {
      // ✅ Firebase register
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);

      // ✅ Set displayName
      const displayName = `${firstName} ${lastName}`.trim();
      await updateProfile(userCredential.user, { displayName });

      message.success("Registration successful! Redirecting to the map...");
      navigate("/map");
    } catch (error) {
      console.error("Firebase registration error:", error);

      // Better messages
      let msg = "Registration failed. Please try again.";
      if (error?.code === "auth/email-already-in-use") msg = "This email is already in use.";
      if (error?.code === "auth/invalid-email") msg = "Please enter a valid email address.";
      if (error?.code === "auth/weak-password") msg = "Password is too weak. Please choose a stronger one.";

      message.error(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="register-card">
      <div className="card-header">
        <span className="vacanza-logo">
          <SendOutlined className="logo-icon" />
          Vacanza
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
              rules={[{ required: true, message: "Please enter your first name!" }]}
            >
              <Input prefix={<UserOutlined />} placeholder="First Name" size="large" autoComplete="given-name" />
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
          rules={[{ required: true, message: "Please enter your last name!" }]}
        >
          <Input prefix={<UserOutlined />} placeholder="Last Name" size="large" autoComplete="family-name" />
        </Form.Item>

        <Form.Item
          name="email"
          rules={[
            { type: "email", message: "Please enter a valid email address!" },
            { required: true, message: "Please enter your email!" },
          ]}
        >
          <Input prefix={<MailOutlined />} placeholder="Email address" size="large" autoComplete="email" />
        </Form.Item>

        <Form.Item
          name="password"
          rules={[{ required: true, message: "Please enter your password!" }]}
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
            { required: true, message: "Please confirm your password!" },
            ({ getFieldValue }) => ({
              validator(_, value) {
                if (!value || getFieldValue("password") === value) return Promise.resolve();
                return Promise.reject(new Error("Passwords do not match!"));
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
                value ? Promise.resolve() : Promise.reject(new Error("You must accept the terms and conditions.")),
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

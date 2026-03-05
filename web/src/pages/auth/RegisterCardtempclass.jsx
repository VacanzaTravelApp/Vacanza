import React, { useState } from 'react';
import { Form, Input, Button, Checkbox, Row, Col, Space, message } from 'antd';
import {
  UserOutlined,
  LockOutlined,
  MailOutlined,
  SendOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import './RegisterCard.css';
import { useNavigate } from 'react-router-dom';

import { createUserWithEmailAndPassword, updateProfile } from 'firebase/auth';
import auth from '../../firebase';

// PasswordChecks Component
const PasswordChecks = ({ password }) => {
  const checks = [
    { text: '8+ characters', valid: password && password.length >= 8 },
    { text: '1+ uppercase', valid: /[A-Z]/.test(password) },
    { text: '1+ lowercase', valid: /[a-z]/.test(password) },
    { text: '1 number', valid: /[0-9]/.test(password) },
    { text: '1 special char', valid: /[^A-Za-z0-9]/.test(password) },
  ];

  if (!password) {
    return null;
  }

  return (
    <Row gutter={[10, 0]} className="password-checks-container">
      {checks.map((check) => (
        <Col span={12} key={check.text}>
          <div className={`password-check-item ${check.valid ? 'valid' : 'invalid'}`}>
            <span className="check-indicator">
              {check.valid ? (
                <CheckCircleOutlined style={{ color: '#52c41a' }} />
              ) : (
                <CloseCircleOutlined style={{ color: '#bfbfbf' }} />
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
  const password = Form.useWatch('password', form);
  const firstName = Form.useWatch('firstName', form);
  const middleName = Form.useWatch('middleName', form);
  const [loading, setLoading] = useState(false);
  const [preferredName, setPreferredName] = useState(null);
  const [showPreferredError, setShowPreferredError] = useState(false);


  const onFinish = async (values) => {
    if (middleName && !preferredName) {
      setShowPreferredError(true);
      setLoading(false);
      return;
    }
    setShowPreferredError(false);

    const { email, password, firstName, lastName } = values;

    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);

      await updateProfile(userCredential.user, {
        displayName: `${firstName} ${lastName}`
      });

      message.success('Registration successful! Redirecting you to the map.');
      console.log('Registration Successful, redirecting to /map');
      navigate('/map');

    } catch (error) {
      console.error("Firebase Registration Error:", error.code, error.message);

      let errorMessage = "An error occurred during registration. Please try again.";
      if (error.code === 'auth/email-already-in-use') {
        errorMessage = "This email address is already in use.";
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = "Invalid email format.";
      } else if (error.code === 'auth/weak-password') {
        errorMessage = "Password is too weak. Please use a stronger password.";
      }

      message.error(errorMessage);

    } finally {
      setLoading(false);
    }
  };


  const handleLoginRedirect = () => {
    navigate('/login');
  };

  return (
    <div className="register-card">
      <div className="card-header">
        <span className="vacanza-logo">
          <SendOutlined className="logo-icon" />
        </span>
        <h3>Create Your <span style={{ color: '#3da8c8' }}>Vacanza</span> Account</h3>
        <p className="header-subtext">
          Start your personalized journey today
        </p>
      </div>

      <Form
        form={form}
        name="register"
        onFinish={onFinish}
        scrollToFirstError
        layout="vertical"
        className="auth-form"
        requiredMark={false}
      >
        <Row gutter={10}>
          <Col xs={24} sm={12}>
            <Form.Item
              name="firstName"
              label="First Name"
              rules={[{ required: true, message: 'First name is required' }]}
            >
              <Input
                placeholder="First Name"
                size="large"
                autoComplete="given-name"
              />
            </Form.Item>
          </Col>

          <Col xs={24} sm={12}>
            <Form.Item
              name="middleName"
              label="Middle Name"
            >
              <Input
                placeholder="Middle Name"
                size="large"
              />
            </Form.Item>
          </Col>
        </Row>

        <Form.Item
          name="lastName"
          label="Last Name"
          rules={[{ required: true, message: 'Last name is required' }]}
        >
          <Input
            placeholder="Last Name"
            size="large"
            autoComplete="family-name"
          />
        </Form.Item>

        {/* Preferred Name selector - only shows when middle name is entered */}
        {middleName && (
          <div className="preferred-name-section">
            <span className="preferred-name-label">Preferred Name</span>
            <Space size={8}>
              {firstName && (
                <button
                  type="button"
                  className={`preferred-chip ${preferredName === 'firstName' ? 'preferred-chip--active' : ''}`}
                  onClick={() => {
                    const newValue = preferredName === 'firstName' ? null : 'firstName';
                    setPreferredName(newValue);
                    if (!newValue) setShowPreferredError(true);
                    else setShowPreferredError(false);
                  }}
                >
                  {preferredName === 'firstName' && <CheckCircleOutlined style={{ marginRight: 4 }} />}
                  {firstName}
                </button>
              )}
              <button
                type="button"
                className={`preferred-chip ${preferredName === 'middleName' ? 'preferred-chip--active' : ''}`}
                onClick={() => {
                  const newValue = preferredName === 'middleName' ? null : 'middleName';
                  setPreferredName(newValue);
                  if (!newValue) setShowPreferredError(true);
                  else setShowPreferredError(false);
                }}
              >
                {preferredName === 'middleName' && <CheckCircleOutlined style={{ marginRight: 4 }} />}
                {middleName}
              </button>
            </Space>
            {showPreferredError && !preferredName && (
              <div style={{ color: '#ff4d4f', fontSize: '12px', marginTop: '4px' }}>
                Please choose at least one preferred name
              </div>
            )}
          </div>
        )}

        <Form.Item
          name="email"
          label="Email"
          rules={[
            { type: 'email', message: 'Enter a valid email' },
            { required: true, message: 'Email is required' },
          ]}
        >
          <Input
            placeholder="you@example.com"
            size="large"
            autoComplete="email"
          />
        </Form.Item>
        <Form.Item
          name="password"
          label="Password"
          rules={[{ required: true, message: 'Password is required' }]}
          hasFeedback
        >
          <Input.Password
            placeholder="Password"
            size="large"
            autoComplete="new-password"
          />
        </Form.Item>

        <PasswordChecks password={password} />

        <Form.Item
          name="confirmPassword"
          label="Confirm Password"
          dependencies={['password']}
          hasFeedback
          rules={[
            { required: true, message: 'Confirm password' },
            ({ getFieldValue }) => ({
              validator(_, value) {
                if (!value || getFieldValue('password') === value) {
                  return Promise.resolve();
                }
                return Promise.reject(new Error('Passwords do not match'));
              },
            }),
          ]}
        >
          <Input.Password
            placeholder="Confirm Password"
            size="large"
            autoComplete="new-password"
          />
        </Form.Item>

        <Form.Item
          name="agreedToTerms"
          valuePropName="checked"
          validateTrigger="onSubmit"
          rules={[
            {
              validator: (_, value) =>
                value ? Promise.resolve() : Promise.reject(new Error('You must accept the terms and conditions')),
            },
          ]}
        >
          <Checkbox>
            I agree to the <a href="#">Terms & Conditions</a> and <a href="#">Privacy Policy</a>
          </Checkbox>
        </Form.Item>
        <Form.Item>
          <Button
            type="primary"
            htmlType="submit"
            className="cta-button"
            size="large"
            loading={loading}
          >
            Sign Up
          </Button>
        </Form.Item>
      </Form>
      <div className="login-redirect">
        Already have a Vacanza account?
        <span onClick={handleLoginRedirect} className="login-link">
          Log In
        </span>
      </div>
    </div>
  );
};

export default RegisterCard;
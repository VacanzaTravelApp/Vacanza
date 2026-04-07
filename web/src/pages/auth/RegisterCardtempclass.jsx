import React, { useState } from 'react';
// Ant Design bileşenleri, hook'ları ve mesajlar
import { Form, Input, Button, Checkbox, Row, Col, Space, message } from 'antd';
import {
  UserOutlined,
  LockOutlined,
  MailOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  CheckOutlined,
} from '@ant-design/icons';
import './RegisterCard.css';
import { useNavigate } from 'react-router-dom';

import { createUserWithEmailAndPassword, updateProfile, sendEmailVerification } from 'firebase/auth'; // <-- updateProfile and sendEmailVerification EKLENDİ
import auth from '../../firebase';
import { authApi } from '../../api/userApi';

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
    <Row gutter={[10, 5]} className="password-checks-container">
      {checks.map((check) => (
        <Col span={12} key={check.text}>
          <div className={`password-check-item ${check.valid ? 'valid' : 'invalid'}`}>
            <span className="check-indicator" style={{ marginRight: '8px' }}>
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


const PreferredNameSelector = ({ value = [], onChange, firstName, middleName }) => {
  const options = [];
  if (firstName && firstName.trim() !== '') options.push(firstName);
  if (middleName && middleName.trim() !== '') options.push(middleName);

  const toggleSelection = (name) => {
    let newValue = [...(value || [])];
    if (newValue.includes(name)) {
      newValue = newValue.filter(n => n !== name);
    } else {
      newValue.push(name);
    }
    onChange(newValue);
  };

  return (
    <div className="preferred-name-options">
      {options.map((name, index) => {
        const isSelected = value?.includes(name);
        return (
          <div
            key={index}
            className={`pn-option ${isSelected ? 'selected' : ''}`}
            onClick={() => toggleSelection(name)}
          >
            {isSelected && <CheckOutlined style={{ marginRight: '6px', fontSize: '12px', fontWeight: 'bold' }} />}
            {name}
          </div>
        );
      })}
    </div>
  );
};

const RegisterCard = () => {
  const navigate = useNavigate();
  const [form] = Form.useForm();
  const password = Form.useWatch('password', form);
  const middleName = Form.useWatch('middleName', form);
  const firstName = Form.useWatch('firstName', form);
  const [loading, setLoading] = useState(false);


  const onFinish = async (values) => {
    setLoading(true);
    const { email, password, firstName, lastName, middleName, preferredName } = values;

    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);

      // 1. Update Firebase Internal Profile
      const dispName = (preferredName && preferredName.length > 0)
        ? preferredName[0]
        : `${firstName} ${lastName}`;

      await updateProfile(userCredential.user, {
        displayName: dispName
      });

      // 2. Sync with Backend Database & Create Session
      await authApi.register({
        email,
        firstName,
        lastName,
        middleName: middleName || null,
        preferredName: (preferredName && preferredName.length > 0) ? preferredName[0] : null
      });

      // Synchronize backend session (Spring Session sync with Firebase token)
      try {
        await authApi.login();
      } catch (loginErr) {
        console.warn("[Register] Session sync skipped or handled by register:", loginErr.message);
      }

      // 3. Send Verification Email
      await sendEmailVerification(userCredential.user);

      console.log('Registration Successful, redirecting to /verify-email');
      navigate('/verify-email');

    } catch (error) {
      console.error("Firebase Registration Error:", error.code, error.message);

      if (error.code === 'auth/email-already-in-use') {
        form.setFields([
          {
            name: 'email',
            errors: ['An account already exists with this email address.'],
          },
        ]);
      } else if (error.code === 'auth/invalid-email') {
        form.setFields([
          {
            name: 'email',
            errors: ['Please enter a valid email address.'],
          },
        ]);
      } else if (error.code === 'auth/weak-password') {
        form.setFields([
          {
            name: 'password',
            errors: ['Your password is too weak. Please choose a stronger one.'],
          },
        ]);
      } else {
        message.error("Oops! Something went wrong during registration. Please try again.");
      }
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
        <h3>Sign Up</h3>
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
        <Row gutter={12}>
          <Col span={12}>
            <Form.Item
              name="firstName"
              rules={[{ required: true, message: 'Please enter your first name!' }]}
            >
              <Input
                prefix={<UserOutlined />}
                placeholder="First Name *"
                size="large"
                autoComplete="given-name"
              />
            </Form.Item>
          </Col>

          <Col span={12}>
            <Form.Item
              name="middleName"
            >
              <Input
                prefix={<UserOutlined />}
                placeholder="Middle Name"
                size="large"
              />
            </Form.Item>
          </Col>
        </Row>

        <Form.Item
          name="lastName"
          rules={[{ required: true, message: 'Please enter your last name!' }]}
        >
          <Input
            prefix={<UserOutlined />}
            placeholder="Last Name *"
            size="large"
            autoComplete="family-name"
          />
        </Form.Item>

        {middleName && middleName.trim() !== '' && (
          <Form.Item
            name="preferredName"
            label={<span style={{ color: '#455A64', fontWeight: 600, fontSize: '13px' }}>Preferred Name</span>}
            rules={[
              {
                validator: (_, value) => {
                  if (!value || value.length === 0) {
                    return Promise.reject(new Error('Please choose at least one preffered name'));
                  }
                  return Promise.resolve();
                }
              }
            ]}
          >
            <PreferredNameSelector firstName={firstName} middleName={middleName} />
          </Form.Item>
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
            prefix={<MailOutlined />}
            placeholder="Email address *"
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
            prefix={<LockOutlined />}
            placeholder="Password *"
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
            prefix={<LockOutlined />}
            placeholder="Confirm Password *"
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

        <div style={{ padding: "0 12px", fontSize: '11px', fontWeight: 700, color: '#455A64', opacity: 0.6, marginBottom: '20px' }}>
          <span style={{ color: '#FF6B6B' }}>*</span> indicates a mandatory field
        </div>

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
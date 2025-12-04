// src/pages/auth/RegisterCard.jsx

import React from 'react';
// Ant Design bileşenleri ve hook'ları
import { Form, Input, Button, Checkbox, Row, Col, Space } from 'antd'; 
// Kullanılacak Ant Design ikonları
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

// PasswordChecks Bileşeni (Değişmedi - Ant Design İkonları ile)
const PasswordChecks = ({ password }) => {
    // Şifre kontrolleri
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


const RegisterCard = () => {
  const navigate = useNavigate(); 
  
  const [form] = Form.useForm(); 
  const password = Form.useWatch('password', form); 

  const onFinish = (values) => {
    console.log('Registration Successful:', values);
    alert('Registration form successfully processed (Demo).');
  };

  const handleLoginRedirect = () => {
    navigate('/login'); 
  };

  return (
    <div className="register-card">
      <div className="card-header">
        <span className="vacanza-logo">
           <SendOutlined className="logo-icon" />
           Vacanza
        </span>
        <h3>Start Your Adventure</h3>
        <p className="header-subtext">
          Create an account and sign in to continue
        </p>
      </div>

      <Form
        form={form} 
        name="register"
        onFinish={onFinish} 
        scrollToFirstError
        layout="vertical" 
        className="auth-form"
      >
        {/* FIRST NAME ve MIDDLE NAME - YAN YANA (Ekran Görüntüsüne Uygun) */}
        <Row gutter={12}>
            {/* First Name (Span 12) */}
            <Col span={12}>
                <Form.Item
                    name="firstName"
                    rules={[{ required: true, message: 'Please enter your first name!' }]}
                >
                    <Input 
                        prefix={<UserOutlined />} 
                        placeholder="First Name" 
                        size="large"
                        autoComplete="given-name" 
                    />
                </Form.Item>
            </Col>

            {/* Middle Name (Span 12) - Görünür oldu */}
            <Col span={12}>
                <Form.Item
                    name="middleName"
                    // Zorunlu değil
                >
                    <Input 
                        prefix={<UserOutlined />} 
                        placeholder="Middle Name (Optional)" 
                        size="large"
                    />
                </Form.Item>
            </Col>
        </Row>

        {/* LAST NAME - ALT ALTA (Tam Genişlik) */}
        <Form.Item
            name="lastName"
            rules={[{ required: true, message: 'Please enter your last name!' }]}
        >
            <Input 
                prefix={<UserOutlined />} 
                placeholder="Last Name" 
                size="large"
                autoComplete="family-name" 
            />
        </Form.Item>


        {/* E-posta inputu (Değişmedi) */}
        <Form.Item
          name="email"
          rules={[
            { type: 'email', message: 'The input is not a valid E-mail!' },
            { required: true, message: 'Please input your E-mail!' },
          ]}
        >
          <Input 
            prefix={<MailOutlined />} 
            placeholder="Email address" 
            size="large" 
            autoComplete="email" 
          />
        </Form.Item>

        {/* Şifre (Password) inputu (Değişmedi) */}
        <Form.Item
          name="password"
          rules={[{ required: true, message: 'Please input your Password!' }]}
          hasFeedback
        >
          <Input.Password 
            prefix={<LockOutlined />} 
            placeholder="Password" 
            size="large" 
            autoComplete="new-password" 
          />
        </Form.Item>
        
        {/* Dinamik Password Checks Bileşeni (Değişmedi) */}
        <PasswordChecks password={password} /> 


        {/* Şifreyi Onayla (Confirm Password) inputu (Değişmedi) */}
        <Form.Item
          name="confirmPassword"
          dependencies={['password']}
          hasFeedback
          rules={[
            { required: true, message: 'Please confirm your Password!' },
            ({ getFieldValue }) => ({
              validator(_, value) {
                if (!value || getFieldValue('password') === value) {
                  return Promise.resolve();
                }
                return Promise.reject(new Error('The two passwords that you entered do not match!'));
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

        {/* Onay ve Şartlar (Değişmedi) */}
        <Form.Item
          name="agreedToTerms"
          valuePropName="checked"
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

        {/* Kayıt Butonu (Değişmedi) */}
        <Form.Item>
          <Button type="primary" htmlType="submit" className="cta-button" size="large">
            Start Your Adventure
          </Button>
        </Form.Item>
      </Form>


      {/* Giriş Yap Yönlendirmesi (Değişmedi) */}
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
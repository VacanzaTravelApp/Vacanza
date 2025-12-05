// src/pages/auth/LoginCard.jsx

import React from 'react';
import { Form, Input, Button, Space } from 'antd'; // Checkbox kaldırıldı
import { 
    LockOutlined, 
    MailOutlined, 
    SendOutlined, // Logo ikonu eklendi 
    // Alt navigasyon ikonları (GlobalOutlined, TeamOutlined, SettingOutlined) kaldırıldı
} from '@ant-design/icons';
import './RegisterCard.css'; 

import { useNavigate } from 'react-router-dom';

const LoginCard = () => {
  const navigate = useNavigate();

  const onFinish = (values) => {
    console.log('Login Successful:', values);
    alert('Login successful! Redirecting to homepage.');
    // navigate('/dashboard'); 
  };

  const handleRegisterRedirect = () => {
    // '/register' yoluna yönlendirir
    navigate('/register'); 
  };
  
  const handleForgotPassword = () => {
      alert('Forgot Password link clicked!');
      // navigate('/forgot-password');
  };


  return (
    <div className="register-card"> {/* Stil için RegisterCard CSS kullanılıyor */}
      <div className="card-header">
        <span className="vacanza-logo">
            <SendOutlined className="logo-icon" /> {/* Logo ikonu eklendi */}
            Vacanza
        </span>
        <h3>Welcome Back to Vacanza</h3>
        <p className="header-subtext">
          Sign in to continue your journey
        </p>
      </div>

      <Form
        name="login"
        initialValues={{ remember: true }}
        onFinish={onFinish} 
        layout="vertical"
        className="auth-form"
      >
        {/* E-posta */}
        <Form.Item
          name="email"
          rules={[
            { type: 'email', message: 'The input is not a valid E-mail!' },
            { required: true, message: 'Please input your E-mail!' },
          ]}
        >
          <Input 
            prefix={<MailOutlined />} 
            placeholder="Enter your email" 
            size="large" 
            autoComplete="email"
          />
        </Form.Item>

        {/* Şifre */}
        <Form.Item
          name="password"
          rules={[{ required: true, message: 'Please input your Password!' }]}
        >
          <Input.Password 
            prefix={<LockOutlined />} 
            placeholder="Enter your password" 
            size="large" 
            autoComplete="current-password"
          />
        </Form.Item>

        {/* Şifremi Unuttum? Linki */}
        <div className="login-options-row">
            {/* Boşluk bırakmak için yer tutucu kullanıyoruz (CSS'teki flex-end için) */}
            <span className="remember-me-placeholder"></span> 
            
            <span onClick={handleForgotPassword} className="forgot-password-link">
                Forgot Password?
            </span>
        </div>

        {/* Giriş Butonu */}
        <Form.Item style={{ marginTop: '20px' }}> {/* Butonun üstüne boşluk ekledik */}
          <Button type="primary" htmlType="submit" className="cta-button" size="large">
            Log In
          </Button>
        </Form.Item>
        
        {/* Alt Navigasyon (Özellik Butonları) bu tasarımda olmadığı için kaldırıldı. */}
      </Form>


      {/* Kayıt Ol Yönlendirmesi */}
      <div className="login-redirect">
        Don't have an Vacanza account? 
        <span onClick={handleRegisterRedirect} className="login-link">
          Sign Up
        </span>
      </div>
    </div>
  );
};

export default LoginCard;
// src/pages/auth/LoginCard.jsx

import React, { useState } from 'react';
import { Form, Input, Button, Typography } from 'antd'; // Typography eklendi
import { 
    LockOutlined, 
    MailOutlined, 
    SendOutlined, 
} from '@ant-design/icons';
// Import ettiğiniz CSS dosyasının adını korudum
import './RegisterCard.css'; 

import { useNavigate } from 'react-router-dom';

// 🚀 FIREBASE IMPORTS
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../../firebase'; // Import the auth object from your firebase.js file

const { Text } = Typography;

const LoginCard = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false); 
  // Hata mesajını formun altında göstermek için state
  const [errorMessage, setErrorMessage] = useState(null); 

  // Firebase giriş denemesi
  const onFinish = async (values) => {
    setLoading(true);
    setErrorMessage(null); // Yeni denemede eski hatayı temizle
    
    const { email, password } = values; 

    try {
        // 🔥 FIREBASE LOGIN PROCESS
        await signInWithEmailAndPassword(auth, email, password);
        
        // SUCCESS: Redirect the user to the /map page
        navigate('/map'); 

    } catch (error) {
        console.error("Firebase Login Error:", error.code, error.message);
        
        let customError;
        
        // 🔥 GÜNCELLENMİŞ HATA YÖNETİMİ
        switch (error.code) {
            case 'auth/user-not-found':
                customError = 'No registered user found for this email address.';
                break;
            case 'auth/wrong-password':
                // 🔥 ŞİFRE YANLIŞ HATASI BURADA YAKALANDI
                customError = 'Incorrect password. Please try again.';
                break;
            case 'auth/invalid-email':
                customError = 'The email address is not valid.';
                break;
            case 'auth/invalid-credential':
                 // Eğer Firebase auth/user-not-found veya auth/wrong-password döndürmek yerine
                 // genel auth/invalid-credential döndürüyorsa, kullanıcıyı bulunamadı olarak yönlendiriyoruz.
                customError = 'Invalid email or password.';
                break;
            default:
                customError = 'An error occurred during login. Please try again.';
        }

        // Hata mesajını state'e kaydet (Butonun altında gösterilecek)
        setErrorMessage(customError); 

    } finally {
        setLoading(false); // İşlem bitince loading state'i kapat
    }
  };

  const handleRegisterRedirect = () => {
    navigate('/register'); 
  };
  
  const handleForgotPassword = () => {
      alert('Forgot Password link clicked!');
      // navigate('/forgot-password');
  };


  return (
    <div className="register-card"> 
      <div className="card-header">
        <span className="vacanza-logo">
            <SendOutlined className="logo-icon" /> 
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
        {/* E-mail */}
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

        {/* Password */}
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

        {/* Forgot Password? Link */}
        <div className="login-options-row">
            <span className="remember-me-placeholder"></span> 
            
            <span onClick={handleForgotPassword} className="forgot-password-link">
                Forgot Password?
            </span>
        </div>

        {/* Login Button */}
        <Form.Item style={{ marginTop: '20px' }}>
          <Button 
            type="primary" 
            htmlType="submit" 
            className="cta-button" 
            size="large"
            loading={loading}
          >
            Log In
          </Button>
        </Form.Item>
        
        {/* 🔥 GÜNCEL KONUM: Hata Mesajı Alanı - Login butonundan hemen SONRA/ALTINDA */}
        {errorMessage && (
            <div style={{ marginTop: -10, marginBottom: 15, textAlign: 'center' }}>
                <Text type="danger">{errorMessage}</Text>
            </div>
        )}
        {/* ---------------------------------------------------------------------- */}
      </Form>


      {/* Redirect to Register */}
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
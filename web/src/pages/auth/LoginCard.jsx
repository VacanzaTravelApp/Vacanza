// src/pages/auth/LoginCard.jsx

import React, { useState } from 'react'; // 👈 useState eklendi
import { Form, Input, Button, Space, message } from 'antd'; // 👈 message eklendi
import { 
    LockOutlined, 
    MailOutlined, 
    SendOutlined, 
} from '@ant-design/icons';
import './RegisterCard.css'; 

import { useNavigate } from 'react-router-dom';

// 🚀 FIREBASE İMPORTLARI EKLENDİ
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../../firebase'; // 👈 Kendi firebase.js dosyanızdan auth objesini import edin

const LoginCard = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false); // 👈 Yükleme durumu eklendi

  // GÜNCEL: Form gönderildiğinde Firebase girişini deneyecek fonksiyon
  const onFinish = async (values) => {
    setLoading(true);
    const { email, password } = values; // Ant Design formundan e-posta ve şifreyi al

    try {
        // 🔥 FIREBASE GİRİŞ İŞLEMİ
        await signInWithEmailAndPassword(auth, email, password);
        
        // BAŞARILI: Kullanıcıyı /map sayfasına yönlendir
        console.log('Login Successful, redirecting to /map');
        navigate('/map'); 

    } catch (error) {
        // HATA: Firebase hata mesajlarını yakala ve kullanıcıya göster
        console.error("Firebase Giriş Hatası:", error.code, error.message);
        
        let errorMessage = "Giriş sırasında bir hata oluştu. Lütfen tekrar deneyin.";
        if (error.code === 'auth/user-not-found' || error.code === 'auth/wrong-password') {
            errorMessage = "Kullanıcı adı veya şifre hatalı.";
        }

        message.error(errorMessage);

    } finally {
        setLoading(false); // İşlem bitince yükleme durumunu kapat
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
    // ... (JSX kodunun geri kalanı aynı kalır) ...

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
        onFinish={onFinish} // 👈 Güncellenmiş fonksiyonu kullanıyoruz
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
            <span className="remember-me-placeholder"></span> 
            
            <span onClick={handleForgotPassword} className="forgot-password-link">
                Forgot Password?
            </span>
        </div>

        {/* Giriş Butonu */}
        <Form.Item style={{ marginTop: '20px' }}>
          <Button 
            type="primary" 
            htmlType="submit" 
            className="cta-button" 
            size="large"
            loading={loading} // 👈 Yükleme durumunu butona bağladık
          >
            Log In
          </Button>
        </Form.Item>
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
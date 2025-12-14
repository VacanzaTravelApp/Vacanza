// src/pages/auth/RegisterCard.jsx

import React, { useState } from 'react';
// Ant Design bileşenleri, hook'ları ve mesajlar
import { Form, Input, Button, Checkbox, Row, Col, Typography } from 'antd'; // Typography eklendi
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

// 🚀 FIREBASE İMPORTLARI
import { createUserWithEmailAndPassword } from 'firebase/auth';
// 🚨 GÜNCEL VE DAHA GÜVENİLİR IMPORT ŞEKLİ
import auth from '../../firebase'; 

const { Text } = Typography; // Hata mesajını biçimlendirmek için

// PasswordChecks Bileşeni (Aynı kalır)
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


const RegisterCard = () => {
  const navigate = useNavigate(); 
  const [form] = Form.useForm(); 
  const password = Form.useWatch('password', form); 
  const [loading, setLoading] = useState(false); 
  // 🔥 YENİ: Hata mesajını formun altında göstermek için state
  const [errorMessage, setErrorMessage] = useState(null); 


  // GÜNCEL: Form gönderildiğinde Firebase kaydını deneyecek fonksiyon
  const onFinish = async (values) => {
    setLoading(true);
    setErrorMessage(null); // Yeni denemede eski hatayı temizle
    
    // Sadece e-posta ve şifreyi alıyoruz
    const { email, password } = values; 

    try {
        // 🔥 FIREBASE KAYIT İŞLEMİ
        await createUserWithEmailAndPassword(auth, email, password);
        
        // Başarı mesajı kaldırıldı, sadece yönlendirme kalır
        navigate('/map'); 

    } catch (error) {
        // HATA: Firebase hata mesajlarını yakala ve kullanıcıya göster
        console.error("Firebase Kayıt Hatası:", error.code, error.message);
        
        let customError;
        
        // 🔥 HATA YÖNETİMİ (İngilizce)
        switch (error.code) {
            case 'auth/email-already-in-use':
                // 🔥 İstenen "Aynı e-posta" hatası
                customError = 'This email address is already registered.'; 
                break;
            case 'auth/invalid-email':
                customError = 'The email address is not valid.';
                break;
            case 'auth/weak-password':
                customError = 'The password is too weak. Please use a stronger password.';
                break;
            default:
                customError = 'An error occurred during registration. Please try again.';
        }

        // Hata mesajını formun altında göstermek için state'e kaydet
        setErrorMessage(customError); 

    } finally {
        setLoading(false); // İşlem bitince yükleme durumunu kapat
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
        {/* FIRST NAME ve MIDDLE NAME - YAN YANA (Aynı kalır) */}
        <Row gutter={12}>
            {/* First Name */}
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

            {/* Middle Name */}
            <Col span={12}>
                <Form.Item
                    name="middleName"
                >
                    <Input 
                        prefix={<UserOutlined />} 
                        placeholder="Middle Name (Optional)" 
                        size="large"
                    />
                </Form.Item>
            </Col>
        </Row>

        {/* LAST NAME - ALT ALTA (Aynı kalır) */}
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


        {/* E-posta inputu (Aynı kalır) */}
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

        {/* Şifre (Password) inputu (Aynı kalır) */}
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
        
        {/* Dinamik Password Checks Bileşeni (Aynı kalır) */}
        <PasswordChecks password={password} /> 


        {/* Şifreyi Onayla (Confirm Password) inputu (Aynı kalır) */}
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

        {/* Onay ve Şartlar (Aynı kalır) */}
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

        {/* Kayıt Butonu */}
        <Form.Item>
          <Button 
            type="primary" 
            htmlType="submit" 
            className="cta-button" 
            size="large"
            loading={loading}
          >
            Start Your Adventure
          </Button>
        </Form.Item>
        
        {/* 🔥 GÜNCEL KONUM: Hata Mesajı Alanı - Butonun hemen ALTINDA */}
        {errorMessage && (
            <div style={{ marginTop: -10, marginBottom: 15, textAlign: 'center' }}>
                <Text type="danger">{errorMessage}</Text>
            </div>
        )}
        {/* ----------------------------------------------------------- */}
      </Form>


      {/* Giriş Yap Yönlendirmesi (Aynı kalır) */}
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
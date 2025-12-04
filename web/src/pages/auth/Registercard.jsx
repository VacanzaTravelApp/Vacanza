// src/pages/auth/RegisterCard.jsx
import React from 'react';
// YENİ: Form'dan useForm ve Form.useWatch'u doğru bir şekilde alıyoruz
import { Form, Input, Button, Checkbox, Row, Col, Space } from 'antd'; 
import { 
  UserOutlined, 
  LockOutlined, 
  MailOutlined, 
  SendOutlined,
} from '@ant-design/icons';
import './RegisterCard.css'; 
import { useNavigate } from 'react-router-dom';

// PasswordChecks (Şifre Kontrol) Bileşeni - Görünümde değişiklik yok
const PasswordChecks = ({ password }) => {
    // Şifre kontrollerini gerçekleştiren basit regex ifadeleri
    const checks = [
        { text: '8+ characters', valid: password && password.length >= 8 },
        { text: '1+ uppercase', valid: /[A-Z]/.test(password) },
        { text: '1+ lowercase', valid: /[a-z]/.test(password) },
        { text: '1 number', valid: /[0-9]/.test(password) },
        { text: '1 special char', valid: /[^A-Za-z0-9]/.test(password) },
    ];

    return (
        <Row gutter={[10, 5]} className="password-checks-container"> 
            {checks.map((check) => (
                <Col span={12} key={check.text}>
                    <div className={`password-check-item ${check.valid ? 'valid' : 'invalid'}`}>
                        {/* Simge: ✅ (Geçerli) ve ⚪ (Geçersiz) */}
                        <span className="check-indicator" style={{ color: check.valid ? '#52c41a' : '#bfbfbf' }}>
                            {check.valid ? '✅' : '⚪'} 
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
  
  // 1. ADIM: Form instance'ı oluşturulur
  const [form] = Form.useForm(); 
  
  // 2. ADIM: 'password' alanındaki değişiklikler izlenir. 
  // Password değeri her değiştiğinde bileşen yeniden render edilir.
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
        {/* ... (Başlık kısmı değişmedi) ... */}
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
        form={form} // 3. ADIM: Form instance'ı bileşene bağlanır
        name="register"
        onFinish={onFinish} 
        scrollToFirstError
        layout="vertical" 
        className="auth-form"
      >
        {/* First Name ve Last Name - Yan Yana */}
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

            {/* Last Name */}
            <Col span={12}>
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
            </Col>
        </Row>


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
            placeholder="Email address" 
            size="large" 
            autoComplete="email" 
          />
        </Form.Item>

        {/* Şifre (Password) */}
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
        
        {/* 4. ADIM: Parola değeri PasswordChecks bileşenine iletilir */}
        <PasswordChecks password={password} /> 


        {/* Şifreyi Onayla (Confirm Password) */}
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

        {/* Onay ve Şartlar (Terms) */}
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

        {/* Kayıt Butonu (Register Button) */}
        <Form.Item>
          <Button type="primary" htmlType="submit" className="cta-button" size="large">
            Start Your Adventure
          </Button>
        </Form.Item>
      </Form>


      {/* Giriş Yap Yönlendirmesi (Login Redirect) */}
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
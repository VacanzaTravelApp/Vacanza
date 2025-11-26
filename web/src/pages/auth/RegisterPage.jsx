import React, { useState } from "react";
import { Form, Input, Button, Typography, Checkbox } from "antd";
import { EyeInvisibleOutlined, EyeTwoTone } from "@ant-design/icons";
import "./RegisterPage.css";

const { Text, Link } = Typography;

const Register = () => {
  const [form] = Form.useForm();
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);

  const onFinish = (values) => {
    console.log("Register form values:", values);
  };

  const handleFieldsChange = () => {
    const hasErrors = form
      .getFieldsError()
      .some(({ errors }) => errors.length > 0);

    const fullName = form.getFieldValue("fullName");
    const email = form.getFieldValue("email");
    const password = form.getFieldValue("password");
    const confirmPassword = form.getFieldValue("confirmPassword");
    const termsChecked = form.getFieldValue("terms");

    const requiredMissing =
      !fullName || !email || !password || !confirmPassword || !termsChecked;

    setIsSubmitDisabled(hasErrors || requiredMissing);
  };

  return (
    <div className="auth-layout">
      <div className="auth-card">
        <div className="auth-header">
          <h2 className="auth-title">
            Create Your <span className="auth-title-accent">VACANZA</span> Account
          </h2>
          <p className="auth-subtitle">Start your personalized journey today</p>
        </div>

        <Form
          form={form}
          layout="vertical"
          className="auth-form"
          onFinish={onFinish}
          onFieldsChange={handleFieldsChange}
        >
          {/* Full Name */}
          <Form.Item
            label="Full Name"
            name="fullName"
            rules={[{ required: true, message: "Please enter your full name" }]}
          >
            <Input placeholder="Enter your full name" />
          </Form.Item>

          {/* Email */}
          <Form.Item
            label="Email"
            name="email"
            rules={[
              { required: true, message: "Please enter your email" },
              { type: "email", message: "Please enter a valid email" },
            ]}
          >
            <Input placeholder="Enter your email" />
          </Form.Item>

          {/* Password */}
          <Form.Item
            label="Password"
            name="password"
            rules={[
              { required: true, message: "Please create a password" },
              { min: 6, message: "Password must be at least 6 characters" },
            ]}
          >
            <Input.Password
              placeholder="Create a password"
              iconRender={(visible) =>
                visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />
              }
            />
          </Form.Item>

          {/* Confirm Password */}
          <Form.Item
            label="Confirm Password"
            name="confirmPassword"
            dependencies={["password"]}
            rules={[
              { required: true, message: "Please confirm your password" },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue("password") === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(
                    new Error("Passwords do not match")
                  );
                },
              }),
            ]}
          >
            <Input.Password
              placeholder="Confirm your password"
              iconRender={(visible) =>
                visible ? <EyeTwoTone /> : <EyeInvisibleOutlined />
              }
            />
          </Form.Item>

          {/* Terms Checkbox */}
          <Form.Item
            name="terms"
            valuePropName="checked"
            rules={[
              {
                validator: (_, value) =>
                  value
                    ? Promise.resolve()
                    : Promise.reject(
                        new Error("You must agree to the terms to continue")
                      ),
              },
            ]}
          >
            <Checkbox>
              I agree to the{" "}
              <Link href="#" className="auth-link">
                Terms &amp; Conditions
              </Link>{" "}
              and{" "}
              <Link href="#" className="auth-link">
                Privacy Policy
              </Link>
            </Checkbox>
          </Form.Item>

          {/* Submit Button */}
          <Form.Item>
            <Button
              type="primary"
              htmlType="submit"
              className="auth-button"
              block
              disabled={isSubmitDisabled}
            >
              Register
            </Button>
          </Form.Item>
        </Form>

        <div className="auth-footer">
          <Text className="auth-footer-text">
            Already have an account?{" "}
            <Link href="#" className="auth-link auth-link-login">
              Login
            </Link>
          </Text>
        </div>
      </div>
    </div>
  );
};

export default Register;

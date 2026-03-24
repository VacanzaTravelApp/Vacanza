import React, { useState } from "react";
import { Layout, Menu, Button, theme, Typography, Avatar, Dropdown, Space, Badge, Modal, Form, Input, Switch, Divider, message } from "antd";
import {
    DesktopOutlined,
    PieChartOutlined,
    UserOutlined,
    LogoutOutlined,
    SettingOutlined,
    MenuFoldOutlined,
    MenuUnfoldOutlined,
    DashboardOutlined,
    BellOutlined
} from "@ant-design/icons";
import { useNavigate, useLocation, Outlet } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { motion, AnimatePresence } from "framer-motion";
import { MdFlightTakeoff } from "react-icons/md";

const { Header, Content, Footer, Sider } = Layout;
const { Title } = Typography;

export default function AdminLayout() {
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    const [collapsed, setCollapsed] = useState(false);
    const [settingsVisible, setSettingsVisible] = useState(false);
    const [adminName, setAdminName] = useState(localStorage.getItem('admin_display_name') || user?.displayName || user?.email?.split('@')[0] || "Admin");
    const [sidebarTheme, setSidebarTheme] = useState(localStorage.getItem('sidebar_theme') || 'dark');
    const [logRefresh, setLogRefresh] = useState(true);

    const [form] = Form.useForm();

    const {
        token: { colorBgContainer, borderRadiusLG },
    } = theme.useToken();

    const menuItems = [
        {
            key: "/",
            icon: <DashboardOutlined />,
            label: "Dashboard",
        },
        {
            key: "/monitoring",
            icon: <DesktopOutlined />,
            label: "Monitoring (UC2.1)",
        },
        {
            key: "/analytics",
            icon: <PieChartOutlined />,
            label: "Analytics (UC2.2)",
        },
    ];

    const userMenuItems = {
        items: [
            { key: "settings", icon: <SettingOutlined />, label: "Settings", onClick: () => setSettingsVisible(true) },
            { type: "divider" },
            { key: "logout", icon: <LogoutOutlined />, label: "Logout", onClick: logout },
        ]
    };

    const handleSettingsSave = () => {
        const values = form.getFieldsValue();
        if (values.displayName) {
            setAdminName(values.displayName);
            localStorage.setItem('admin_display_name', values.displayName);
        }
        const newTheme = values.sidebarTheme ? 'dark' : 'light';
        localStorage.setItem('sidebar_theme', newTheme);
        setSidebarTheme(newTheme);
        setLogRefresh(values.logRefresh);

        setSettingsVisible(false);
    };

    return (
        <Layout style={{ minHeight: "100vh", background: '#f5f7fa' }}>
            <Sider
                trigger={null}
                collapsible
                collapsed={collapsed}
                breakpoint="lg"
                collapsedWidth="0"
                onBreakpoint={(broken) => {
                    if (broken) setCollapsed(true);
                }}
                theme={sidebarTheme}
                style={{ height: '100vh', position: 'sticky', top: 0, left: 0, zIndex: 1001 }}
            >
                <div style={{ height: "64px", margin: "16px", display: "flex", alignItems: "center", justifyContent: "center", background: sidebarTheme === 'dark' ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.02)', borderRadius: '8px', overflow: 'hidden' }}>
                    {!collapsed && (
                        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <MdFlightTakeoff style={{ fontSize: '24px', color: '#1677ff' }} />
                            <Title level={4} style={{ color: sidebarTheme === 'dark' ? "white" : "#001529", margin: 0, letterSpacing: '1px' }}>VACANZA</Title>
                        </motion.div>
                    )}
                    {collapsed && <MdFlightTakeoff style={{ fontSize: '24px', color: '#1677ff' }} />}
                </div>
                <Menu
                    theme={sidebarTheme}
                    mode="inline"
                    selectedKeys={[location.pathname]}
                    items={menuItems}
                    onClick={({ key }) => {
                        navigate(key);
                        if (window.innerWidth <= 992) setCollapsed(true);
                    }}
                    style={{ border: 'none' }}
                />
            </Sider>
            <Layout>
                <Header style={{ padding: '0 24px', background: colorBgContainer, display: "flex", justifyContent: "space-between", alignItems: "center", boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
                    <Button
                        type="text"
                        icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
                        onClick={() => setCollapsed(!collapsed)}
                        style={{ fontSize: "16px", width: 44, height: 44 }}
                    />
                    <Space size="large">
                        <Dropdown menu={userMenuItems} placement="bottomRight">
                            <Space style={{ cursor: "pointer", padding: '4px 8px', borderRadius: 8, transition: 'background 0.3s' }} className="user-dropdown-trigger">
                                <Avatar shape="square" icon={<UserOutlined />} style={{ background: '#1677ff', borderRadius: 6 }} />
                                {window.innerWidth >= 576 && (
                                    <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1 }}>
                                        <span style={{ fontSize: '14px', fontWeight: 600 }}>
                                            {adminName}
                                        </span>
                                        <span style={{ fontSize: '11px', color: 'gray' }}>Administrator</span>
                                    </div>
                                )}
                            </Space>
                        </Dropdown>
                    </Space>
                </Header>
                <Content style={{ margin: window.innerWidth < 576 ? "8px" : "24px", minHeight: 280, borderRadius: borderRadiusLG }}>
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={location.pathname}
                            initial={{ opacity: 0, x: 10 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: -10 }}
                            transition={{ duration: 0.3 }}
                        >
                            <Outlet />
                        </motion.div>
                    </AnimatePresence>
                </Content>
                <Footer style={{ textAlign: "center", background: 'transparent', color: 'rgba(0,0,0,0.45)' }}>Vacanza Admin Panel • Operational Control Center v2.4.1</Footer>
            </Layout>

            <Modal
                title={<Space><SettingOutlined /> Admin Settings</Space>}
                open={settingsVisible}
                onCancel={() => setSettingsVisible(false)}
                onOk={handleSettingsSave}
                width={500}
                centered
                destroyOnClose={false}
            >
                <Divider style={{ margin: '12px 0' }} />
                <Form
                    form={form}
                    layout="vertical"
                    initialValues={{
                        displayName: adminName,
                        email: user?.email || "",
                        sidebarTheme: sidebarTheme === 'dark',
                        logRefresh: logRefresh,
                        dataPrecision: true
                    }}
                >
                    <Form.Item label="Display Name" name="displayName">
                        <Input prefix={<UserOutlined />} placeholder="Enter your name..." />
                    </Form.Item>
                    <Form.Item label="Email (Primary)" name="email">
                        <Input disabled />
                    </Form.Item>

                    <Divider orientation="left" plain>UI Preferences</Divider>

                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                        <span>Real-time Log Refresh</span>
                        <Form.Item name="logRefresh" valuePropName="checked" style={{ margin: 0 }}>
                            <Switch />
                        </Form.Item>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 12 }}>
                        <span>Dark Theme Sidebar</span>
                        <Form.Item name="sidebarTheme" valuePropName="checked" style={{ margin: 0 }}>
                            <Switch />
                        </Form.Item>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                        <span>High Data Precision</span>
                        <Form.Item name="dataPrecision" valuePropName="checked" style={{ margin: 0 }}>
                            <Switch />
                        </Form.Item>
                    </div>
                </Form>
            </Modal>
        </Layout>
    );
}

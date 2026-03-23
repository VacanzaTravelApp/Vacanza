import React, { useState } from "react";
import { Layout, Menu, Button, theme, Typography, Avatar, Dropdown, Space, Badge } from "antd";
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
    const [collapsed, setCollapsed] = useState(false);
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();
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
            { key: "settings", icon: <SettingOutlined />, label: "Settings" },
            { type: "divider" },
            { key: "logout", icon: <LogoutOutlined />, label: "Logout", onClick: logout },
        ]
    };

    return (
        <Layout style={{ minHeight: "100vh", background: '#f5f7fa' }}>
            <Sider trigger={null} collapsible collapsed={collapsed} theme="dark" style={{ position: 'sticky', top: 0, height: '100vh', left: 0 }}>
                <div style={{ height: "64px", margin: "16px", display: "flex", alignItems: "center", justifyContent: "center", background: 'rgba(255,255,255,0.05)', borderRadius: '8px', overflow: 'hidden' }}>
                    {!collapsed && (
                        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <MdFlightTakeoff style={{ fontSize: '24px', color: '#1677ff' }} />
                            <Title level={4} style={{ color: "white", margin: 0, letterSpacing: '1px' }}>VACANZA</Title>
                        </motion.div>
                    )}
                    {collapsed && <MdFlightTakeoff style={{ fontSize: '24px', color: '#1677ff' }} />}
                </div>
                <Menu
                    theme="dark"
                    mode="inline"
                    selectedKeys={[location.pathname]}
                    items={menuItems}
                    onClick={({ key }) => navigate(key)}
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
                                <div className="hide-on-mobile" style={{ display: 'flex', flexDirection: 'column', lineHeight: 1 }}>
                                    <span style={{ fontSize: '14px', fontWeight: 600 }}>
                                        {user?.displayName || user?.preferredName || user?.email || "Admin User"}
                                    </span>
                                    <span style={{ fontSize: '11px', color: 'gray' }}>Administrator</span>
                                </div>
                            </Space>
                        </Dropdown>
                    </Space>
                </Header>
                <Content style={{ margin: "24px", minHeight: 280, borderRadius: borderRadiusLG }}>
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
                <Footer style={{ textAlign: "center", background: 'transparent', color: 'rgba(0,0,0,0.45)' }}>Vacanza Admin Panel • Operational Control Center</Footer>
            </Layout>
        </Layout>
    );
}

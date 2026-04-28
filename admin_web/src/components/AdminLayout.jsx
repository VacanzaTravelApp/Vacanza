import React, { useEffect, useState } from "react";
import { Layout, Menu, Button, Typography, Avatar, Dropdown, Space, Badge, message, Grid } from "antd";
import {
    UserOutlined,
    LogoutOutlined,
    MenuFoldOutlined,
    MenuUnfoldOutlined,
    DashboardOutlined,
    ThunderboltOutlined,
    GlobalOutlined,
    RocketOutlined
} from "@ant-design/icons";
import { useNavigate, useLocation, Outlet, Link } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { motion, AnimatePresence } from "framer-motion";

const { Header, Content, Footer, Sider } = Layout;
const { Title, Text } = Typography;
const { useBreakpoint } = Grid;

const THEME = {
    coral: '#FF6B6B',
    navy: '#1A2332',
    teal: '#00B4D8',
    white: '#FFFFFF',
    text: '#1A2332',
    subtext: '#5A6B7A',
    glass: 'rgba(255, 255, 255, 0.85)',
    border: 'rgba(26, 35, 50, 0.08)'
};

const BRAND_COLOR = '#FF6B6B'; // Web App Coral
const SIDEBAR_DARK = '#1A2332'; // Web App Navy

export default function AdminLayout() {
    const screens = useBreakpoint();
    const isMobile = !screens.md;
    const isTablet = !!screens.md && !screens.lg;
    const [collapsed, setCollapsed] = useState(false);
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    useEffect(() => {
        if (isMobile) {
            setCollapsed(true);
        }
    }, [isMobile]);

    useEffect(() => {
        if (isMobile) {
            setCollapsed(true);
        }
    }, [isMobile, location.pathname]);

    const menuItems = [
        { key: "/", icon: <DashboardOutlined style={{ fontSize: 18 }} />, label: "Home Console" },
        { key: "/monitoring", icon: <ThunderboltOutlined style={{ fontSize: 18 }} />, label: "System Matrix" },
        { key: "/analytics", icon: <GlobalOutlined style={{ fontSize: 18 }} />, label: "Analytics Core" },
        { key: "/users", icon: <UserOutlined style={{ fontSize: 18 }} />, label: "User Access" },
    ];

    const handleLogout = async () => {
        try {
            await logout();
        } catch (error) {
            message.error("Security protocols blocked disconnect.");
        }
    };

    const userMenuItems = {
        items: [
            {
                key: "logout",
                icon: <LogoutOutlined />,
                label: <span style={{ color: THEME.coral, fontWeight: 700 }}>Disconnect</span>,
                onClick: handleLogout
            },
        ]
    };

    return (
        <Layout style={{ minHeight: "100vh", background: '#f8faff', overflowX: 'hidden' }}>
            <Sider
                trigger={null}
                collapsible
                collapsed={collapsed}
                breakpoint="lg"
                collapsedWidth="0"
                onCollapse={(c) => setCollapsed(c)}
                width={280}
                style={{
                    position: isMobile ? 'fixed' : 'sticky',
                    top: 0,
                    height: '100vh',
                    left: 0,
                    zIndex: 100,
                    background: THEME.navy,
                    boxShadow: '12px 0 40px rgba(26, 35, 50, 0.12)',
                    overflow: 'auto'
                }}
            >
                <div
                    onClick={() => window.location.reload()}
                    style={{
                        minHeight: "90px",
                        margin: "32px 16px",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        background: 'transparent',
                        cursor: 'pointer'
                    }}>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px' }}>
                        <img
                            src="/logo.svg"
                            alt="Vacanza"
                            style={{
                                height: collapsed ? "40px" : "80px",
                                width: "auto",
                                objectFit: "contain",
                                transition: 'all 0.3s'
                            }}
                        />
                        {!collapsed && (
                            <div style={{ textAlign: 'center', animation: 'fadeIn 0.5s' }}>
                                <div style={{
                                    color: '#fff',
                                    fontSize: '18px',
                                    fontWeight: 900,
                                    letterSpacing: '4px',
                                    fontFamily: "'Fraunces', serif"
                                }}>
                                    VACANZA
                                </div>
                                <div style={{
                                    color: 'rgba(255, 255, 255, 0.45)',
                                    fontSize: '10px',
                                    fontWeight: 700,
                                    letterSpacing: '2px',
                                    marginTop: '-2px'
                                }}>
                                    ADMIN CONSOLE
                                </div>
                            </div>
                        )}
                    </div>
                </div>

                <Menu
                    theme="dark"
                    mode="inline"
                    selectedKeys={[location.pathname]}
                    style={{ background: 'transparent', border: 'none', padding: isMobile ? '0 12px 24px' : '0 16px 24px' }}
                    items={menuItems.map(item => ({
                        ...item,
                        style: {
                            borderRadius: '14px', marginBottom: '8px', fontSize: '14px', fontWeight: 600, height: '52px', lineHeight: '52px',
                            backgroundColor: location.pathname === item.key ? 'rgba(255, 107, 107, 0.12)' : 'transparent',
                            color: location.pathname === item.key ? THEME.coral : 'rgba(255,255,255,0.6)'
                        },
                        label: <Link to={item.key}>{item.label}</Link>
                    }))}
                />
            </Sider>

            {isMobile && !collapsed && (
                <div
                    onClick={() => setCollapsed(true)}
                    style={{
                        position: 'fixed',
                        inset: 0,
                        background: 'rgba(26, 35, 50, 0.38)',
                        zIndex: 95
                    }}
                />
            )}

            <Layout style={{ minWidth: 0, overflowX: 'hidden' }}>
                <Header style={{
                    padding: isMobile ? '0 16px' : '0 40px',
                    background: THEME.glass,
                    backdropFilter: 'blur(24px)',
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    height: isMobile ? '72px' : '88px',
                    borderBottom: `1px solid ${THEME.border}`,
                    zIndex: 90,
                    position: 'sticky',
                    top: 0,
                    gap: 12
                }}>
                    <Space size={isMobile ? "middle" : "large"} style={{ minWidth: 0 }}>
                        <Button
                            type="text"
                            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
                            onClick={() => setCollapsed(!collapsed)}
                            style={{ fontSize: "18px", width: 44, height: 44, borderRadius: '12px', color: THEME.navy, background: 'rgba(26, 35, 50, 0.04)', flexShrink: 0 }}
                        />
                        {(isMobile || isTablet) && (
                            <div style={{ minWidth: 0 }}>
                                <Text strong style={{ display: 'block', color: THEME.navy, fontSize: isMobile ? 15 : 16, lineHeight: 1.1 }}>
                                    {menuItems.find(item => item.key === location.pathname)?.label || "Admin Console"}
                                </Text>
                                {!isMobile && (
                                    <Text style={{ fontSize: 11, color: THEME.subtext, textTransform: 'uppercase', fontWeight: 700, letterSpacing: 1 }}>
                                        Vacanza Admin
                                    </Text>
                                )}
                            </div>
                        )}
                    </Space>
                    <Space size="large" style={{ flexShrink: 0 }}>
                        <Dropdown menu={userMenuItems} placement="bottomRight" arrow>
                            <Space style={{ cursor: "pointer", padding: isMobile ? '4px' : '8px 16px', borderRadius: 16, background: 'rgba(26, 35, 50, 0.04)' }}>
                                <Avatar shape="square" src={user?.photoURL} icon={<UserOutlined />} style={{ background: THEME.coral, borderRadius: 10 }} />
                                {!isMobile && (
                                    <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.1 }}>
                                        <Text strong style={{ fontSize: '14px', color: THEME.navy }}>{user?.displayName || "Admin"}</Text>
                                        <Text style={{ fontSize: '10px', color: THEME.subtext, textTransform: 'uppercase', fontWeight: 700 }}>System Core</Text>
                                    </div>
                                )}
                            </Space>
                        </Dropdown>
                    </Space>
                </Header>

                <Content style={{ minWidth: 0, overflowX: 'hidden' }}>
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={location.pathname}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            transition={{ duration: 0.3 }}
                        >
                            <Outlet />
                        </motion.div>
                    </AnimatePresence>
                </Content>

                <Footer style={{ textAlign: "center", background: 'transparent', padding: isMobile ? '20px 16px 28px' : '32px' }}>
                    <Text style={{ fontSize: 11, color: THEME.subtext, fontWeight: 600, opacity: 0.6 }}>
                        VACANZA INFRASTRUCTURE • v1.0.0-PROD • © 2026
                    </Text>
                </Footer>
            </Layout>
        </Layout>
    );
}

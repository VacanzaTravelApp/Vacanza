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
    BellOutlined,
    ThunderboltOutlined,
    GlobalOutlined
} from "@ant-design/icons";
import { useNavigate, useLocation, Outlet } from "react-router-dom";
import { useAuth } from "../context/useAuth";
import { motion, AnimatePresence } from "framer-motion";
import { MdFlightTakeoff } from "react-icons/md";

const { Header, Content, Footer, Sider } = Layout;
const { Title, Text } = Typography;

const BRAND_COLOR = 'hsl(250, 89%, 66%)';
const SIDEBAR_DARK = 'hsl(222, 47%, 11%)';

export default function AdminLayout() {
    const [collapsed, setCollapsed] = useState(false);
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const location = useLocation();

    const menuItems = [
        {
            key: "/",
            icon: <DashboardOutlined style={{ fontSize: 18 }} />,
            label: "Home Console",
        },
        {
            key: "/monitoring",
            icon: <ThunderboltOutlined style={{ fontSize: 18 }} />,
            label: "System Matrix",
        },
        {
            key: "/analytics",
            icon: <GlobalOutlined style={{ fontSize: 18 }} />,
            label: "Analytics Core",
        },
    ];

    const userMenuItems = {
        items: [
            { key: "settings", icon: <SettingOutlined />, label: "Profile Matrix" },
            { type: "divider" },
            {
                key: "logout",
                icon: <LogoutOutlined />,
                label: <span style={{ color: '#ff4d4f' }}>Disconnect Session</span>,
                onClick: logout
            },
        ]
    };

    return (
        <Layout style={{ minHeight: "100vh", background: '#f8fafc' }}>
            <Sider
                trigger={null}
                collapsible
                collapsed={collapsed}
                breakpoint="lg"
                collapsedWidth="0"
                onCollapse={(c) => setCollapsed(c)}
                width={260}
                style={{
                    position: 'sticky',
                    top: 0,
                    height: '100vh',
                    left: 0,
                    zIndex: 100,
                    background: SIDEBAR_DARK,
                    boxShadow: '4px 0 24px rgba(0,0,0,0.1)'
                }}
            >
                <div style={{
                    height: "64px",
                    margin: "24px 16px 32px",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    background: 'rgba(255,255,255,0.03)',
                    borderRadius: '16px',
                    overflow: 'hidden',
                    border: '1px solid rgba(255,255,255,0.05)'
                }}>
                    <motion.div
                        initial={false}
                        animate={{ gap: collapsed ? 0 : 12 }}
                        style={{ display: 'flex', alignItems: 'center' }}
                    >
                        <div style={{
                            width: 32,
                            height: 32,
                            borderRadius: '8px',
                            background: BRAND_COLOR,
                            display: 'flex',
                            justifyContent: 'center',
                            alignItems: 'center',
                            boxShadow: `0 0 15px ${BRAND_COLOR}44`
                        }}>
                            <MdFlightTakeoff style={{ fontSize: '18px', color: 'white' }} />
                        </div>
                        {!collapsed && (
                            <Title level={4} style={{
                                color: "white",
                                margin: 0,
                                letterSpacing: '2px',
                                fontFamily: "'Outfit', sans-serif",
                                fontWeight: 700
                            }}>VACANZA</Title>
                        )}
                    </motion.div>
                </div>
                <Menu
                    theme="dark"
                    mode="inline"
                    selectedKeys={[location.pathname]}
                    items={menuItems}
                    onClick={({ key }) => navigate(key)}
                    style={{
                        background: 'transparent',
                        border: 'none',
                        padding: '0 12px'
                    }}
                    className="custom-sidebar-menu"
                />
            </Sider>
            <Layout>
                <Header style={{
                    padding: '0 32px',
                    background: 'rgba(255,255,255,0.8)',
                    backdropFilter: 'blur(10px)',
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    height: '72px',
                    borderBottom: '1px solid #f1f5f9',
                    zIndex: 10
                }}>
                    <Button
                        type="text"
                        icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
                        onClick={() => setCollapsed(!collapsed)}
                        style={{ fontSize: "18px", width: 44, height: 44, borderRadius: '12px' }}
                    />
                    <Space size="large">
                        <Badge dot status="error" offset={[-4, 4]}>
                            <Button type="text" icon={<BellOutlined />} style={{ fontSize: '20px', color: '#64748b' }} />
                        </Badge>
                        <Dropdown menu={userMenuItems} placement="bottomRight" arrow>
                            <Space style={{ cursor: "pointer", padding: '6px 12px', borderRadius: 12, transition: 'all 0.3s', background: '#f1f5f9' }}>
                                <Avatar shape="square" icon={<UserOutlined />} style={{ background: BRAND_COLOR, borderRadius: 8, boxShadow: `0 4px 10px ${BRAND_COLOR}33` }} />
                                <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.2, marginLeft: 4 }}>
                                    <Text strong style={{ fontSize: '13px', color: '#1e293b' }}>
                                        {user?.displayName || user?.email?.split('@')[0] || "Matrix.Admin"}
                                    </Text>
                                    <Text type="secondary" style={{ fontSize: '10px', textTransform: 'uppercase', letterSpacing: 0.5 }}>System Administrator</Text>
                                </div>
                            </Space>
                        </Dropdown>
                    </Space>
                </Header>
                <Content style={{ margin: "32px", minHeight: 280 }}>
                    <AnimatePresence mode="wait">
                        <motion.div
                            key={location.pathname}
                            initial={{ opacity: 0, scale: 0.99, y: 10 }}
                            animate={{ opacity: 1, scale: 1, y: 0 }}
                            exit={{ opacity: 0, scale: 0.99, y: -10 }}
                            transition={{ duration: 0.4, ease: [0.4, 0, 0.2, 1] }}
                        >
                            <Outlet />
                        </motion.div>
                    </AnimatePresence>
                </Content>
                <Footer style={{ textAlign: "center", background: 'transparent', color: '#94a3b8', fontSize: '12px', padding: '24px' }}>
                    <Text type="secondary" style={{ fontSize: 11 }}>Vacanza Admin Console • v1.0.0-PROD • Professional Core Engine © 2026</Text>
                </Footer>
            </Layout>
        </Layout>
    );
}

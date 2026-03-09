import React, { useState, useEffect } from "react";
import {
    Modal, Avatar, Typography, Tag, Spin, Progress,
    Form, Input, Select, DatePicker, InputNumber, Button,
    Row, Col, Divider, message
} from "antd";
import {
    TrophyOutlined,
    RightOutlined,
    UserOutlined,
    SlidersOutlined,
    BarChartOutlined,
    ArrowLeftOutlined,
    SaveOutlined
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { useQueryClient, useMutation } from "@tanstack/react-query";
import { useUserPreferences } from "../hooks/useUserPreferences";
import { useUserProfile, useUserStats } from "../hooks/useUserProfileData";
import { userApi } from "../api/userApi";
import dayjs from "dayjs";

const { Title, Text } = Typography;
const { Option } = Select;

const ProfileModal = ({ open, onClose, user, gamification, gamificationLoading }) => {
    const navigate = useNavigate();
    const queryClient = useQueryClient();

    // View Management: 'MAIN', 'EDIT_PROFILE', 'EDIT_PREFERENCES'
    const [view, setView] = useState('MAIN');

    // Data Sources
    const { data: profile, isLoading: profileLoading } = useUserProfile();
    const { data: preferences, isLoading: prefsLoading } = useUserPreferences();
    const { data: stats, isLoading: statsLoading } = useUserStats();

    const loading = gamificationLoading || profileLoading || prefsLoading || statsLoading;

    // Reset view when modal closes
    useEffect(() => {
        if (!open) {
            setTimeout(() => setView('MAIN'), 300);
        }
    }, [open]);

    // --- Mutations ---
    const updateProfileMutation = useMutation({
        mutationFn: (values) => userApi.updateProfile(values),
        onSuccess: () => {
            queryClient.invalidateQueries(["user", "profile"]);
            message.success("Your profile is all set! ✨");
            setView('MAIN');
        },
        onError: () => message.error("Failed to update profile")
    });

    const updatePrefsMutation = useMutation({
        mutationFn: (values) => userApi.updatePreferences(values),
        onSuccess: () => {
            queryClient.invalidateQueries(["user", "preferences"]);
            message.success("Preferences updated! 🌍");
            setView('MAIN');
        },
        onError: () => message.error("Failed to update preferences")
    });

    // --- Components / Sub-views ---

    const MainView = () => (
        <div style={{ padding: "24px 24px 40px", maxHeight: "85vh", overflowY: "auto" }}>
            <Title level={2} style={{ marginTop: 0, marginBottom: 24, fontWeight: 850, color: "#1c1c1e", letterSpacing: "-0.5px" }}>
                Profile
            </Title>

            {/* --- 1. Header Area --- */}
            <div style={{ background: "rgba(224, 247, 250, 0.45)", backdropFilter: "blur(12px)", WebkitBackdropFilter: "blur(12px)", border: "1px solid rgba(255, 255, 255, 0.6)", borderRadius: 28, padding: "24px", display: "flex", alignItems: "center", gap: 20, marginBottom: 20, boxShadow: "0 8px 32px rgba(31, 38, 135, 0.04)" }}>
                <div style={{ position: "relative" }}>
                    <div style={{ width: 84, height: 84, borderRadius: "50%", padding: 4, background: "linear-gradient(135deg, #00acc1 0%, #4caf50 100%)", display: "flex", alignItems: "center", justifyContent: "center", boxShadow: "0 4px 12px rgba(0, 172, 193, 0.2)" }}>
                        <Avatar size={76} src={profile?.profileImageUrl || user?.photoURL} icon={<UserOutlined />} style={{ border: "3px solid white", background: "#1890ff" }} />
                    </div>
                    <div style={{ position: "absolute", bottom: -2, right: -2, background: "#ffb74d", color: "#fff", fontWeight: 900, fontSize: 13, borderRadius: "50%", width: 28, height: 28, display: "flex", alignItems: "center", justifyContent: "center", border: "2px solid #fff", boxShadow: "0 4px 8px rgba(0,0,0,0.12)" }}>
                        {gamification?.levelText?.replace(/\D/g, '') || "1"}
                    </div>
                </div>
                <div>
                    <div style={{ fontSize: 22, fontWeight: 900, color: "#1c1c1e", lineHeight: 1.1 }}>{profile?.displayName || user?.displayName || "Traveler"}</div>
                    <div style={{ display: "inline-block", background: "#fff", borderRadius: 12, padding: "4px 12px", fontSize: 13, fontWeight: 700, color: "#6b7280", marginTop: 8, marginBottom: 6, boxShadow: "0 2px 4px rgba(0,0,0,0.02)" }}>
                        {gamification?.roleText || "Explorer"}
                    </div>
                    <div style={{ fontSize: 13, fontWeight: 700, color: "#007aff" }}>{`Level ${gamification?.levelText?.replace(/\D/g, '') || 1} • ${gamification?.totalXp || 0} XP`}</div>
                </div>
            </div>

            {/* --- 2. Gamification --- */}
            <div onClick={() => { onClose(); navigate("/gamification"); }} className="profile-nav-card" style={{ background: "#fff", borderRadius: 24, padding: "20px 24px", cursor: "pointer", marginBottom: 16, boxShadow: "0 4px 12px rgba(0,0,0,0.02)" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 16 }}>
                    <div style={{ width: 44, height: 44, borderRadius: 14, background: "linear-gradient(135deg, #ffcc80 0%, #ff9800 100%)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                        <TrophyOutlined style={{ fontSize: 22, color: "#fff" }} />
                    </div>
                    <div style={{ flex: 1 }}><div style={{ fontSize: 15, fontWeight: 800, color: "#111827", marginBottom: 2 }}>Gamification</div><div style={{ fontSize: 12, color: "#9ca3af", fontWeight: 500 }}>XP, badges, and challenges</div></div>
                    <RightOutlined style={{ fontSize: 12, color: "#d1d5db" }} />
                </div>
                <div style={{ padding: "0 4px" }}>
                    <Progress percent={gamification?.xpProgressPercent || 0} strokeColor={{ '0%': '#ffb74d', '100%': '#ff9800' }} showInfo={false} size="small" />
                    <div style={{ display: "flex", justifyContent: "space-between", marginTop: 6 }}>
                        <Text style={{ fontSize: 11, fontWeight: 700, color: "#9ca3af" }}>{gamification?.xpToNextLevel} XP to next level</Text>
                        <Text style={{ fontSize: 11, fontWeight: 800, color: "#1c1c1e" }}>{gamification?.xpProgressPercent}%</Text>
                    </div>
                </div>
            </div>

            {/* --- 3. Travel Preferences --- */}
            <div className="profile-nav-card" style={{ background: "#fff", borderRadius: 24, padding: "20px 24px", marginBottom: 16, boxShadow: "0 4px 12px rgba(0,0,0,0.02)" }}>
                <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 16 }}>
                    <div style={{ width: 44, height: 44, borderRadius: 14, background: "linear-gradient(135deg, #02abfd 0%, #007aff 100%)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                        <SlidersOutlined style={{ fontSize: 22, color: "#fff" }} />
                    </div>
                    <div style={{ flex: 1 }}><div style={{ fontSize: 15, fontWeight: 800, color: "#111827", marginBottom: 2 }}>Travel Preferences</div><div style={{ fontSize: 12, color: "#9ca3af", fontWeight: 500 }}>Personalize recommendations</div></div>
                    <RightOutlined style={{ fontSize: 12, color: "#d1d5db" }} />
                </div>
                <div style={{ paddingLeft: 60 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}><span style={{ fontSize: 13, color: "#9ca3af", fontWeight: 600 }}>Travel style</span><span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 800 }}>{preferences?.travelStyle || "—"}</span></div>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, alignItems: "flex-start" }}><span style={{ fontSize: 13, color: "#9ca3af", fontWeight: 600 }}>Categories</span><div style={{ display: "flex", flexWrap: "wrap", gap: 6, justifyContent: "flex-end", maxWidth: "60%" }}>{preferences?.favoriteCategories?.map((cat, idx) => (<Tag key={idx} color="blue" bordered={false} style={{ margin: 0, borderRadius: 8, fontSize: 11, fontWeight: 750 }}>{cat}</Tag>)) || "—"}</div></div>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}><span style={{ fontSize: 13, color: "#9ca3af", fontWeight: 600 }}>Daily budget</span><span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 800 }}>{preferences?.dailyBudget ? `${preferences.dailyBudget} ${preferences.budgetCurrency || "EUR"}` : "—"}</span></div>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}><span style={{ fontSize: 13, color: "#9ca3af", fontWeight: 600 }}>Dietary</span><div style={{ display: "flex", flexWrap: "wrap", gap: 4, justifyContent: "flex-end" }}>{preferences?.dietaryRestrictions?.map((diet, idx) => (<Tag key={idx} color="error" bordered={false} style={{ margin: 0, borderRadius: 8, fontSize: 11, fontWeight: 750, background: "rgba(255, 77, 79, 0.08)", color: "#ff4d4f" }}>{diet}</Tag>)) || "—"}</div></div>
                </div>
            </div>

            {/* --- 4. Travel Stats --- */}
            <div style={{ background: "#fff", borderRadius: 24, padding: "20px 24px", boxShadow: "0 4px 12px rgba(0,0,0,0.02)", marginBottom: 16 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: 16 }}>
                    <div style={{ width: 44, height: 44, borderRadius: 14, background: "linear-gradient(135deg, #4ade80 0%, #22c55e 100%)", display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0 }}>
                        <BarChartOutlined style={{ fontSize: 22, color: "#fff" }} />
                    </div>
                    <div style={{ flex: 1 }}><div style={{ fontSize: 15, fontWeight: 800, color: "#111827", marginBottom: 2 }}>Travel Statistics</div><div style={{ fontSize: 12, color: "#9ca3af", fontWeight: 500 }}>Your journey so far</div></div>
                </div>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                    {loading ? <div style={{ gridColumn: "span 2", padding: 20, textAlign: "center" }}><Spin size="small" /></div> : (
                        <>
                            <div style={{ background: "#f8f9fa", borderRadius: 16, padding: "12px 16px", border: "1px solid #f1f3f5" }}><div style={{ fontSize: 22, fontWeight: 900, color: "#1c1c1e" }}>{stats?.visitedPoisCount ?? 0}</div><div style={{ fontSize: 11, fontWeight: 600, color: "#9ca3af" }}>Places</div></div>
                            <div style={{ background: "#f8f9fa", borderRadius: 16, padding: "12px 16px", border: "1px solid #f1f3f5" }}><div style={{ fontSize: 22, fontWeight: 900, color: "#1c1c1e" }}>{gamification?.stats?.find(s => s.label === "Badges")?.value ?? 0}</div><div style={{ fontSize: 11, fontWeight: 600, color: "#9ca3af" }}>Badges</div></div>
                            <div style={{ background: "#f8f9fa", borderRadius: 16, padding: "12px 16px", border: "1px solid #f1f3f5", gridColumn: "span 2" }}><div style={{ fontSize: 20, fontWeight: 900, color: "#1c1c1e", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{stats?.lastVisitPoiName || "No check-ins yet"}</div><div style={{ fontSize: 11, fontWeight: 600, color: "#9ca3af" }}>{stats?.lastVisitDate ? new Date(stats.lastVisitDate).toLocaleDateString() : "Your latest discovery"}</div></div>
                        </>
                    )}
                </div>
            </div>

            {/* --- 5. Actions --- */}
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                <div onClick={() => setView('EDIT_PROFILE')} style={{ background: "rgba(255, 255, 255, 0.8)", borderRadius: 20, padding: "16px 20px", display: "flex", justifyContent: "space-between", alignItems: "center", cursor: "pointer", border: "1px solid #eee" }}>
                    <span style={{ fontWeight: 700, fontSize: 14 }}>Edit Profile</span>
                    <RightOutlined style={{ fontSize: 12, color: "#9ca3af" }} />
                </div>
                <div onClick={() => setView('EDIT_PREFERENCES')} style={{ background: "rgba(255, 255, 255, 0.8)", borderRadius: 20, padding: "16px 20px", display: "flex", justifyContent: "space-between", alignItems: "center", cursor: "pointer", border: "1px solid #eee" }}>
                    <span style={{ fontWeight: 700, fontSize: 14 }}>Edit Preferences</span>
                    <RightOutlined style={{ fontSize: 12, color: "#9ca3af" }} />
                </div>
                <div onClick={() => { import("../firebase").then(({ auth }) => auth.signOut()); onClose(); navigate("/login"); }} style={{ background: "rgba(255, 77, 79, 0.05)", borderRadius: 20, padding: "16px 20px", display: "flex", justifyContent: "center", alignItems: "center", cursor: "pointer", marginTop: 10 }}>
                    <span style={{ fontWeight: 800, fontSize: 14, color: "#ff4d4f" }}>Logout</span>
                </div>
            </div>
        </div>
    );

    const EditProfileView = () => (
        <div style={{ padding: "24px 24px 40px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 24 }}>
                <Button icon={<ArrowLeftOutlined />} shape="circle" borderless="true" onClick={() => setView('MAIN')} />
                <Title level={3} style={{ margin: 0, fontWeight: 800 }}>Edit Profile</Title>
            </div>

            <Form
                layout="vertical"
                initialValues={{
                    ...profile,
                    birthDate: profile?.birthDate ? dayjs(profile.birthDate) : null
                }}
                onFinish={(v) => updateProfileMutation.mutate({
                    ...v,
                    birthDate: v.birthDate ? v.birthDate.format('YYYY-MM-DD') : null
                })}
            >
                <Row gutter={16}>
                    <Col span={12}>
                        <Form.Item label="First Name" name="firstName" rules={[{ required: true }]}>
                            <Input placeholder="First Name" style={{ borderRadius: 12 }} />
                        </Form.Item>
                    </Col>
                    <Col span={12}>
                        <Form.Item label="Last Name" name="lastName" rules={[{ required: true }]}>
                            <Input placeholder="Last Name" style={{ borderRadius: 12 }} />
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item label="Preferred Name" name="preferredName">
                    <Input placeholder="Nickname" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Form.Item label="Country" name="country">
                    <Input placeholder="Turkey" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Row gutter={16}>
                    <Col span={12}>
                        <Form.Item label="Birth Date" name="birthDate">
                            <DatePicker style={{ width: '100%', borderRadius: 12 }} />
                        </Form.Item>
                    </Col>
                    <Col span={12}>
                        <Form.Item label="Gender" name="gender">
                            <Select style={{ borderRadius: 12 }}>
                                <Option value="MALE">Male</Option>
                                <Option value="FEMALE">Female</Option>
                                <Option value="OTHER">Other</Option>
                                <Option value="PREFER_NOT_TO_SAY">Prefer not to say</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item label="Profile Image URL" name="profileImageUrl">
                    <Input placeholder="https://..." style={{ borderRadius: 12 }} />
                </Form.Item>

                <Button
                    type="primary"
                    htmlType="submit"
                    block
                    icon={<SaveOutlined />}
                    loading={updateProfileMutation.isLoading}
                    style={{ height: 48, borderRadius: 16, marginTop: 12, background: "linear-gradient(135deg, #02abfd 0%, #007aff 100%)", border: "none", fontWeight: 700 }}
                >
                    Save Changes
                </Button>
            </Form>
        </div>
    );

    const EditPreferencesView = () => (
        <div style={{ padding: "24px 24px 40px" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 24 }}>
                <Button icon={<ArrowLeftOutlined />} shape="circle" borderless="true" onClick={() => setView('MAIN')} />
                <Title level={3} style={{ margin: 0, fontWeight: 800 }}>Travel Preferences</Title>
            </div>

            <Form
                layout="vertical"
                initialValues={preferences}
                onFinish={(v) => updatePrefsMutation.mutate(v)}
            >
                <Row gutter={16}>
                    <Col span={12}>
                        <Form.Item label="Travel Style" name="travelStyle">
                            <Select style={{ borderRadius: 12 }}>
                                <Option value="RELAXED">Relaxed</Option>
                                <Option value="ADVENTURE">Adventure</Option>
                                <Option value="LUXURY">Luxury</Option>
                                <Option value="BACKPACKER">Backpacker</Option>
                                <Option value="CULTURAL">Cultural</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                    <Col span={12}>
                        <Form.Item label="Activity Level" name="activityLevel">
                            <Select style={{ borderRadius: 12 }}>
                                <Option value="LOW">Low</Option>
                                <Option value="MODERATE">Moderate</Option>
                                <Option value="HIGH">High</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item label="Favorite Categories" name="favoriteCategories">
                    <Select mode="tags" placeholder="Add categories" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Divider style={{ margin: "12px 0" }} />

                <Row gutter={16}>
                    <Col span={14}>
                        <Form.Item label="Daily Budget" name="dailyBudget">
                            <InputNumber min={0} style={{ width: '100%', borderRadius: 12 }} />
                        </Form.Item>
                    </Col>
                    <Col span={10}>
                        <Form.Item label="Currency" name="budgetCurrency">
                            <Select style={{ borderRadius: 12 }}>
                                <Option value="EUR">EUR</Option>
                                <Option value="USD">USD</Option>
                                <Option value="TRY">TRY</Option>
                                <Option value="GBP">GBP</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item label="Dietary Restrictions" name="dietaryRestrictions">
                    <Select mode="tags" placeholder="e.g. gluten, peanuts" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Form.Item label="Preferred Language" name="preferredLanguage">
                    <Input placeholder="en" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Button
                    type="primary"
                    htmlType="submit"
                    block
                    icon={<SaveOutlined />}
                    loading={updatePrefsMutation.isLoading}
                    style={{ height: 48, borderRadius: 16, marginTop: 12, background: "linear-gradient(135deg, #4ade80 0%, #22c55e 100%)", border: "none", fontWeight: 700 }}
                >
                    Save Preferences
                </Button>
            </Form>
        </div>
    );

    return (
        <Modal
            open={open}
            onCancel={onClose}
            footer={null}
            width={440}
            centered
            closeIcon={true}
            styles={{ body: { padding: "0", background: "#f8f9fa" } }}
            style={{ borderRadius: "32px", overflow: "hidden" }}
        >
            {view === 'MAIN' && <MainView />}
            {view === 'EDIT_PROFILE' && <EditProfileView />}
            {view === 'EDIT_PREFERENCES' && <EditPreferencesView />}

            <style jsx="true">{`
                .profile-nav-card:hover {
                    background: #fdfdfd !important;
                    transform: translateY(-2px);
                    box-shadow: 0 8px 16px rgba(0,0,0,0.05) !important;
                    transition: all 0.3s ease;
                }
            `}</style>
        </Modal>
    );
};

export default ProfileModal;

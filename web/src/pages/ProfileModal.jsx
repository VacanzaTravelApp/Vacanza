import React, { useState, useEffect, useMemo } from "react";
import {
    Modal, Avatar, Typography, Tag, Spin, Progress,
    Form, Input, Select, DatePicker, InputNumber, Button,
    Row, Col, Divider, message, Empty, Badge as AntBadge
} from "antd";
import {
    TrophyOutlined,
    RightOutlined,
    UserOutlined,
    SlidersOutlined,
    BarChartOutlined,
    ArrowLeftOutlined,
    SaveOutlined,
    EnvironmentOutlined,
    CalendarOutlined,
    StarOutlined,
    FireOutlined,
    ClockCircleOutlined,
    GlobalOutlined,
    LockOutlined,
    CheckCircleFilled,
    MailOutlined,
    HeartOutlined,
    ThunderboltOutlined,
    CompassOutlined,
    LogoutOutlined
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { useQueryClient, useMutation } from "@tanstack/react-query";
import { useUserPreferences } from "../hooks/useUserPreferences";
import { useUserProfile, useUserStats, useUserCheckins } from "../hooks/useUserProfileData";
import { useGamificationProfile } from "../gamification/useGamificationProfile";
import { userApi } from "../api/userApi";
import dayjs from "dayjs";

const { Title, Text } = Typography;
const { Option } = Select;

// Badge icon mapping
const BADGE_ICON_MAP = {
    first_step: "📍",
    foodie: "🍴",
    speed: "⚡",
    culture: "🏛️",
    nature: "🌲",
    explorer: "🧭",
    photographer: "📸",
    adventurer: "🏔️",
    social: "👥",
    night_owl: "🦉",
    early_bird: "🐦",
    globetrotter: "✈️",
    collector: "🏆",
    historian: "📜",
    art_lover: "🎨",
};

function getBadgeIcon(key) {
    return BADGE_ICON_MAP[key] || "🏅";
}

// Date formatting helper
function formatJoinDate(dateStr) {
    if (!dateStr) return null;
    const d = new Date(dateStr);
    const months = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"];
    return `Member since ${months[d.getMonth()]} ${d.getFullYear()}`;
}

function formatDate(dateStr) {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleDateString("en-US", {
        year: "numeric", month: "short", day: "numeric"
    });
}

function formatDateTime(dateStr) {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleDateString("en-US", {
        year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit"
    });
}

// --- Reusable mini components ---

const SectionCard = ({ icon, iconBg, title, subtitle, onClick, extra, children, style = {} }) => (
    <div
        className={onClick ? "profile-nav-card" : ""}
        onClick={onClick}
        style={{
            background: "#fff",
            borderRadius: 24,
            padding: "20px 24px",
            marginBottom: 16,
            boxShadow: "0 4px 12px rgba(0,0,0,0.02)",
            cursor: onClick ? "pointer" : "default",
            transition: "all 0.3s ease",
            ...style
        }}
    >
        <div style={{ display: "flex", alignItems: "center", gap: 16, marginBottom: children ? 20 : 0 }}>
            <div style={{
                width: 48, height: 48, borderRadius: 16,
                background: iconBg,
                display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
                boxShadow: "0 4px 10px rgba(0,0,0,0.05)"
            }}>
                {icon}
            </div>
            <div style={{ flex: 1 }}>
                <div style={{ fontSize: 16, fontWeight: 800, color: "#1c1c1e", lineHeight: 1.2 }}>{title}</div>
                {subtitle && <div style={{ fontSize: 13, color: "#8e8e93", fontWeight: 500, marginTop: 2 }}>{subtitle}</div>}
            </div>
            {extra && <div onClick={(e) => { e.stopPropagation(); extra.onClick(); }} style={{ fontSize: 14, fontWeight: 700, color: "#007aff", cursor: "pointer" }}>{extra.text}</div>}
            {onClick && !extra && <RightOutlined style={{ fontSize: 12, color: "#c7c7cc" }} />}
        </div>
        {children}
    </div>
);

const AccountListItem = ({ icon, iconBg, label, onClick, color = "#1c1c1e", isLast = false, hasChevron = true, background = "#fff" }) => (
    <div
        onClick={onClick}
        style={{
            display: "flex",
            alignItems: "center",
            padding: "16px 0",
            cursor: "pointer",
            borderBottom: isLast ? "none" : "1px solid #f2f2f7",
            background: background,
            transition: "all 0.2s ease",
        }}
        className="profile-list-item"
    >
        <div style={{
            width: 36,
            height: 36,
            borderRadius: 10,
            background: iconBg,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            marginRight: 16,
            flexShrink: 0
        }}>
            {React.cloneElement(icon, { style: { fontSize: 18, color: color === "#ff3b30" ? "#ff3b30" : "#1c1c1e" } })}
        </div>
        <span style={{ flex: 1, fontWeight: 700, fontSize: 15, color: color }}>{label}</span>
        {hasChevron && <RightOutlined style={{ fontSize: 12, color: "#c7c7cc" }} />}
    </div>
);

const InfoRow = ({ label, value }) => (
    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, alignItems: "flex-start" }}>
        <span style={{ fontSize: 13, color: "#9ca3af", fontWeight: 600 }}>{label}</span>
        <span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 800, textAlign: "right", maxWidth: "60%" }}>{value || "—"}</span>
    </div>
);

const ChipRow = ({ label, items, color = "blue" }) => (
    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8, alignItems: "flex-start" }}>
        <span style={{ fontSize: 13, color: "#9ca3af", fontWeight: 600, flexShrink: 0 }}>{label}</span>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 6, justifyContent: "flex-end", maxWidth: "65%" }}>
            {items?.length > 0 ? items.map((item, idx) => (
                <Tag key={idx} color={color} bordered={false} style={{ margin: 0, borderRadius: 8, fontSize: 11, fontWeight: 750 }}>
                    {item}
                </Tag>
            )) : <span style={{ fontSize: 13, color: "#d1d5db" }}>—</span>}
        </div>
    </div>
);

const StatBox = ({ value, label, span = 1 }) => (
    <div style={{
        background: "#f8f9fa", borderRadius: 16, padding: "12px 16px",
        border: "1px solid #f1f3f5", gridColumn: span > 1 ? `span ${span}` : undefined
    }}>
        <div style={{ fontSize: 22, fontWeight: 900, color: "#1c1c1e", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{value}</div>
        <div style={{ fontSize: 11, fontWeight: 600, color: "#9ca3af" }}>{label}</div>
    </div>
);


// ================= MAIN COMPONENT =================

const ProfileModal = ({ open, onClose, user }) => {
    const navigate = useNavigate();
    const queryClient = useQueryClient();

    // View Management
    const [view, setView] = useState('MAIN');

    // Data Sources — all from backend
    const { data: profile, isLoading: profileLoading } = useUserProfile();
    const { data: preferences, isLoading: prefsLoading } = useUserPreferences();
    const { data: stats, isLoading: statsLoading } = useUserStats();
    const { data: checkins, isLoading: checkinsLoading } = useUserCheckins();
    const { data: gamification, isLoading: gamificationLoading } = useGamificationProfile();

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
        onError: (err) => {
            const msg = err?.friendlyMessage || err?.response?.data?.message || "Failed to update profile";
            message.error(msg);
        }
    });

    const updatePrefsMutation = useMutation({
        mutationFn: (values) => userApi.updatePreferences(values),
        onSuccess: () => {
            queryClient.invalidateQueries(["user", "preferences"]);
            message.success("Preferences updated! 🌍");
            setView('MAIN');
        },
        onError: (err) => {
            const msg = err?.friendlyMessage || err?.response?.data?.message || "Failed to update preferences";
            message.error(msg);
        }
    });

    // --- Sub Views ---

    const MainView = () => (
        <div style={{ padding: "24px 24px 40px", maxHeight: "85vh", overflowY: "auto" }}>
            <Title level={2} style={{ marginTop: 0, marginBottom: 24, fontWeight: 850, color: "#1c1c1e", letterSpacing: "-0.5px" }}>
                Profile
            </Title>

            {/* ====== 1. HEADER AREA (GET /users/me/profile) ====== */}
            <div
                className="profile-header-area"
                style={{
                    background: "rgba(224, 247, 250, 0.45)", backdropFilter: "blur(12px)", WebkitBackdropFilter: "blur(12px)",
                    border: "1px solid rgba(255, 255, 255, 0.6)", borderRadius: 28, padding: "24px",
                    display: "flex", alignItems: "center", gap: 20, marginBottom: 20,
                    boxShadow: "0 8px 32px rgba(31, 38, 135, 0.04)"
                }}
            >
                <div style={{ position: "relative" }}>
                    <div style={{
                        width: 84, height: 84, borderRadius: "50%", padding: 4,
                        background: "linear-gradient(135deg, #00acc1 0%, #4caf50 100%)",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        boxShadow: "0 4px 12px rgba(0, 172, 193, 0.2)"
                    }}>
                        <Avatar size={76} src={profile?.profileImageUrl || user?.photoURL} icon={<UserOutlined />}
                            style={{ border: "3px solid white", background: "#1890ff" }} />
                    </div>
                    <div style={{
                        position: "absolute", bottom: -2, right: -2, background: "#ffb74d", color: "#fff",
                        fontWeight: 900, fontSize: 13, borderRadius: "50%", width: 28, height: 28,
                        display: "flex", alignItems: "center", justifyContent: "center",
                        border: "2px solid #fff", boxShadow: "0 4px 8px rgba(0,0,0,0.12)"
                    }}>
                        {gamification?.levelText?.replace(/\D/g, '') || "1"}
                    </div>
                </div>
                <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 22, fontWeight: 900, color: "#1c1c1e", lineHeight: 1.1 }}>
                        {profile?.displayName || user?.displayName || "Traveler"}
                    </div>
                    <div style={{ fontSize: 13, color: "#6b7280", fontWeight: 600, marginTop: 4, display: "flex", alignItems: "center", gap: 4 }}>
                        <MailOutlined style={{ fontSize: 11 }} /> {profile?.email || user?.email || "—"}
                    </div>
                    <div style={{
                        display: "inline-block", background: "#fff", borderRadius: 12, padding: "4px 12px",
                        fontSize: 13, fontWeight: 700, color: "#6b7280", marginTop: 8, marginBottom: 4,
                        boxShadow: "0 2px 4px rgba(0,0,0,0.02)"
                    }}>
                        {gamification?.roleText || "Explorer"}
                    </div>
                    {profile?.joinDate && (
                        <div style={{ fontSize: 12, color: "#9ca3af", fontWeight: 600, marginTop: 2, display: "flex", alignItems: "center", gap: 4 }}>
                            <CalendarOutlined style={{ fontSize: 10 }} /> {formatJoinDate(profile.joinDate)}
                        </div>
                    )}
                </div>
            </div>

            {/* ====== 2. BASIC INFO (GET /users/me/profile) ====== */}
            <SectionCard
                icon={<UserOutlined style={{ fontSize: 22, color: "#fff" }} />}
                iconBg="linear-gradient(135deg, #a78bfa 0%, #7c3aed 100%)"
                title="Basic Info"
                subtitle="Personal details"
            >
                <div style={{ paddingLeft: 60 }}>
                    <InfoRow label="First name" value={profile?.firstName} />
                    {profile?.middleName && <InfoRow label="Middle name" value={profile.middleName} />}
                    <InfoRow label="Last name" value={profile?.lastName} />
                    {profile?.preferredName && <InfoRow label="Preferred name" value={profile.preferredName} />}
                    <InfoRow label="Country" value={profile?.country} />
                    <InfoRow label="Birth date" value={profile?.birthDate ? formatDate(profile.birthDate) : null} />
                    <InfoRow label="Gender" value={profile?.gender ? profile.gender.charAt(0) + profile.gender.slice(1).toLowerCase().replace(/_/g, ' ') : null} />
                </div>
            </SectionCard>

            {/* ====== 3. GAMIFICATION (GET /users/me/gamification) ====== */}
            <SectionCard
                icon={<TrophyOutlined style={{ fontSize: 22, color: "#fff" }} />}
                iconBg="linear-gradient(135deg, #ffcc80 0%, #ff9800 100%)"
                title="Gamification"
                subtitle="XP, badges, and challenges"
                onClick={() => { onClose(); navigate("/gamification"); }}
            >
                {/* XP Progress */}
                <div style={{ padding: "0 4px" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                        <Text style={{ fontSize: 13, fontWeight: 800, color: "#1c1c1e" }}>
                            {gamification?.roleText || "Explorer"} • {gamification?.levelText || "Level 1"}
                        </Text>
                        <Text style={{ fontSize: 13, fontWeight: 800, color: "#ff9800" }}>
                            {gamification?.totalXp || 0} XP
                        </Text>
                    </div>
                    <Progress
                        percent={gamification?.xpProgressPercent || 0}
                        strokeColor={{ '0%': '#ffb74d', '100%': '#ff9800' }}
                        showInfo={false}
                        size="small"
                    />
                    <div style={{ display: "flex", justifyContent: "space-between", marginTop: 6 }}>
                        <Text style={{ fontSize: 11, fontWeight: 700, color: "#9ca3af" }}>
                            {gamification?.xpToNextLevel || 0} XP to next level
                        </Text>
                        <Text style={{ fontSize: 11, fontWeight: 800, color: "#1c1c1e" }}>
                            {gamification?.xpProgressPercent || 0}%
                        </Text>
                    </div>
                </div>

                {/* Stat cards */}
                {Array.isArray(gamification?.stats) && gamification.stats.length > 0 && (
                    <div style={{ display: "flex", gap: 10, marginTop: 16 }}>
                        {gamification.stats.map((stat, idx) => (
                            <div key={idx} style={{
                                flex: 1, background: "#f8f9fa", borderRadius: 14,
                                padding: "10px 12px", textAlign: "center", border: "1px solid #f1f3f5"
                            }}>
                                <div style={{ fontSize: 20, fontWeight: 900, color: "#1c1c1e" }}>
                                    {stat?.value ?? "—"}
                                </div>
                                <div style={{ fontSize: 11, fontWeight: 600, color: "#9ca3af" }}>
                                    {stat?.label ?? "—"}
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Badge grid (compact) */}
                {Array.isArray(gamification?.badges) && gamification.badges.length > 0 && (
                    <div style={{ marginTop: 16 }}>
                        <div style={{ fontSize: 13, fontWeight: 800, color: "#111827", marginBottom: 10 }}>
                            {gamification?.badgesSectionTitle || "Achievement Badges"}
                        </div>
                        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(90px, 1fr))", gap: 8 }}>
                            {gamification.badges.map((badge) => (
                                <div key={badge.id} style={{
                                    background: badge.earned ? "#fffbe6" : "#fafafa",
                                    borderRadius: 14, padding: "10px 6px", textAlign: "center",
                                    border: badge.earned ? "1px solid #ffe58f" : "1px solid #f0f0f0",
                                    opacity: badge.earned ? 1 : 0.45,
                                    filter: badge.earned ? "none" : "grayscale(1)",
                                    transition: "all 0.3s ease",
                                    position: "relative"
                                }}>
                                    <div style={{ fontSize: 24, marginBottom: 4 }}>{getBadgeIcon(badge.key)}</div>
                                    <div style={{ fontSize: 10, fontWeight: 700, color: "#434343", lineHeight: 1.2 }}>
                                        {badge.title}
                                    </div>
                                    {badge.earned && (
                                        <CheckCircleFilled style={{ position: "absolute", top: 4, right: 4, fontSize: 12, color: "#52c41a" }} />
                                    )}
                                    {!badge.earned && (
                                        <LockOutlined style={{ position: "absolute", top: 4, right: 4, fontSize: 10, color: "#d9d9d9" }} />
                                    )}
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </SectionCard>

            {/* ====== 4. TRAVEL PREFERENCES (GET /users/me/preferences) ====== */}
            <SectionCard
                icon={<SlidersOutlined style={{ fontSize: 22, color: "#fff" }} />}
                iconBg="linear-gradient(135deg, #02abfd 0%, #007aff 100%)"
                title="Travel Preferences"
                subtitle="Personalize recommendations"
            >
                <div style={{ paddingLeft: 60 }}>
                    <InfoRow label="Travel style" value={preferences?.travelStyle} />
                    <ChipRow label="Categories" items={preferences?.favoriteCategories} color="blue" />
                    <InfoRow label="Activity level" value={preferences?.activityLevel} />
                    <ChipRow label="Cuisine" items={preferences?.cuisinePreferences} color="cyan" />
                    <ChipRow label="Dietary" items={preferences?.dietaryRestrictions} color="error" />
                    <ChipRow label="Accessibility" items={preferences?.accessibilityNeeds} color="purple" />
                    <InfoRow label="Trip pace" value={preferences?.tripPace} />
                    <InfoRow label="Accommodation" value={preferences?.accommodationType} />
                    <InfoRow label="Transport" value={preferences?.transportPreference} />
                    <InfoRow label="Daily budget" value={
                        preferences?.dailyBudget
                            ? `${preferences.dailyBudget} ${preferences.budgetCurrency || "EUR"}`
                            : null
                    } />
                    <InfoRow label="Language" value={preferences?.preferredLanguage} />
                    <ChipRow label="Spoken" items={preferences?.spokenLanguages} color="green" />
                </div>
            </SectionCard>

            {/* ====== 5. TRAVEL STATISTICS (GET /users/me/stats) ====== */}
            <SectionCard
                icon={<BarChartOutlined style={{ fontSize: 22, color: "#fff" }} />}
                iconBg="linear-gradient(135deg, #4ade80 0%, #22c55e 100%)"
                title="Travel Statistics"
                subtitle="Your journey so far"
            >
                {loading ? (
                    <div style={{ padding: 20, textAlign: "center" }}><Spin size="small" /></div>
                ) : stats?.visitedPoisCount > 0 ? (
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                        <StatBox value={stats?.visitedPoisCount ?? 0} label="Places visited" />
                        <StatBox value={stats?.distinctCategoriesCount ?? 0} label="Categories explored" />
                        <StatBox value={stats?.favoriteCategory ?? "—"} label="Favorite category" />
                        <StatBox
                            value={stats?.lastVisitDate ? formatDate(stats.lastVisitDate) : "—"}
                            label="Last visit"
                        />
                        {stats?.lastVisitPoiName && (
                            <StatBox value={stats.lastVisitPoiName} label="Latest discovery" span={2} />
                        )}
                    </div>
                ) : (
                    <Empty
                        description="No check-ins yet. Start exploring to see your stats!"
                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                        style={{ padding: "12px 0" }}
                    />
                )}
            </SectionCard>

            {/* ====== 6. CHECK-IN HISTORY (GET /users/me/checkins) ====== */}
            <SectionCard
                icon={<ClockCircleOutlined style={{ fontSize: 24, color: "#fff" }} />}
                iconBg="linear-gradient(135deg, #ffb347 0%, #ffcc33 100%)"
                title="Check-in History"
                subtitle="Places you've visited"
                extra={{ text: "See all", onClick: () => { } }} // Action for later if needed
            >
                {checkinsLoading ? (
                    <div style={{ padding: 20, textAlign: "center" }}><Spin size="small" /></div>
                ) : Array.isArray(checkins) && checkins.length > 0 ? (
                    <div style={{ padding: "0" }}>
                        {checkins.slice(0, 3).map((ci, idx) => ( // Show only last 3 for compactness as in screenshot
                            <div key={ci.checkInId || idx} style={{
                                display: "flex", alignItems: "center", gap: 14, padding: "12px 0",
                                borderBottom: idx < Math.min(checkins.length, 3) - 1 ? "1px solid #f2f2f7" : "none",
                                cursor: "pointer"
                            }}>
                                <div style={{
                                    width: 40, height: 40, borderRadius: "50%",
                                    background: "rgba(255, 179, 71, 0.1)",
                                    display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0
                                }}>
                                    <EnvironmentOutlined style={{ fontSize: 18, color: "#ffb347" }} />
                                </div>
                                <div style={{ flex: 1, minWidth: 0 }}>
                                    <div style={{
                                        fontSize: 15, fontWeight: 800, color: "#1c1c1e",
                                        whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
                                        lineHeight: 1.2, marginBottom: 4
                                    }}>
                                        {ci.poiName}
                                    </div>
                                    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                                        <Tag bordered={false} icon={<GlobalOutlined style={{ fontSize: 10 }} />} style={{
                                            margin: 0, borderRadius: 6, fontSize: 11,
                                            fontWeight: 700, textTransform: "capitalize",
                                            background: "#f2f2f7", color: "#8e8e93", padding: "1px 6px"
                                        }}>
                                            {ci.category}
                                        </Tag>
                                        <span style={{ fontSize: 12, color: "#8e8e93", fontWeight: 500 }}>
                                            {formatDate(ci.checkedInAt)}
                                        </span>
                                    </div>
                                </div>
                                <RightOutlined style={{ fontSize: 12, color: "#c7c7cc" }} />
                            </div>
                        ))}
                    </div>
                ) : (
                    <Empty
                        description="No check-ins yet. Visit places to build your history!"
                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                        style={{ padding: "12px 0" }}
                    />
                )}
            </SectionCard>

            {/* ====== 7. ACCOUNT ACTIONS (LIST STYLE) ====== */}
            <div style={{
                background: "#fff",
                borderRadius: 24,
                padding: "16px 20px",
                boxShadow: "0 4px 12px rgba(0,0,0,0.02)",
                marginBottom: 20
            }}>
                <div style={{
                    fontSize: 12, fontWeight: 800, color: "#8e8e93",
                    letterSpacing: "0.5px", marginBottom: 8, paddingLeft: 4
                }}>ACCOUNT</div>

                <AccountListItem
                    icon={<UserOutlined />}
                    iconBg="#eef4ff"
                    label="Edit Profile"
                    onClick={() => setView('EDIT_PROFILE')}
                />
                <AccountListItem
                    icon={<SlidersOutlined />}
                    iconBg="#f0fdf4"
                    label="Edit Preferences"
                    onClick={() => setView('EDIT_PREFERENCES')}
                />
                <AccountListItem
                    icon={<LogoutOutlined style={{ color: "#ff3b30" }} />}
                    iconBg="rgba(255, 59, 48, 0.05)"
                    label="Logout"
                    color="#ff3b30"
                    isLast={true}
                    background="rgba(255, 59, 48, 0.03)"
                    onClick={() => {
                        import("../firebase").then(({ auth }) => auth.signOut());
                        onClose();
                        navigate("/login");
                    }}
                />
            </div>
        </div>
    );

    // ================= EDIT PROFILE VIEW =================
    const EditProfileView = () => (
        <div style={{ padding: "24px 24px 40px", maxHeight: "85vh", overflowY: "auto" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 24 }}>
                <Button icon={<ArrowLeftOutlined />} shape="circle" onClick={() => setView('MAIN')} />
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
                    <Col xs={24} sm={12}>
                        <Form.Item label="First Name" name="firstName" rules={[{ required: true }]}>
                            <Input placeholder="First Name" style={{ borderRadius: 12 }} />
                        </Form.Item>
                    </Col>
                    <Col xs={24} sm={12}>
                        <Form.Item label="Last Name" name="lastName" rules={[{ required: true }]}>
                            <Input placeholder="Last Name" style={{ borderRadius: 12 }} />
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item label="Middle Name" name="middleName">
                    <Input placeholder="Middle Name (optional)" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Form.Item label="Preferred Name" name="preferredName">
                    <Input placeholder="Nickname (used as display name)" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Form.Item label="Country" name="country">
                    <Input placeholder="e.g. Turkey" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Row gutter={16}>
                    <Col span={12}>
                        <Form.Item label="Birth Date" name="birthDate">
                            <DatePicker style={{ width: '100%', borderRadius: 12 }} />
                        </Form.Item>
                    </Col>
                    <Col span={12}>
                        <Form.Item label="Gender" name="gender">
                            <Select style={{ borderRadius: 12 }} allowClear placeholder="Select">
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
                    loading={updateProfileMutation.isPending}
                    style={{
                        height: 48, borderRadius: 16, marginTop: 12,
                        background: "linear-gradient(135deg, #02abfd 0%, #007aff 100%)",
                        border: "none", fontWeight: 700
                    }}
                >
                    Save Changes
                </Button>
            </Form>
        </div>
    );

    // ================= EDIT PREFERENCES VIEW (ALL FIELDS) =================
    const EditPreferencesView = () => (
        <div style={{ padding: "24px 24px 40px", maxHeight: "85vh", overflowY: "auto" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 24 }}>
                <Button icon={<ArrowLeftOutlined />} shape="circle" onClick={() => setView('MAIN')} />
                <Title level={3} style={{ margin: 0, fontWeight: 800 }}>Travel Preferences</Title>
            </div>

            <Form
                layout="vertical"
                initialValues={preferences}
                onFinish={(v) => {
                    // Clean and validate data types for backend DTO (BigDecimal for numbers, List for tags)
                    const payload = {
                        travelStyle: v.travelStyle || null,
                        favoriteCategories: Array.isArray(v.favoriteCategories) ? v.favoriteCategories : [],
                        activityLevel: v.activityLevel || null,
                        cuisinePreferences: Array.isArray(v.cuisinePreferences) ? v.cuisinePreferences : [],
                        preferredClimate: v.preferredClimate || null,
                        tripPace: v.tripPace || null,
                        accommodationType: v.accommodationType || null,
                        transportPreference: v.transportPreference || null,
                        dietaryRestrictions: Array.isArray(v.dietaryRestrictions) ? v.dietaryRestrictions : [],
                        accessibilityNeeds: Array.isArray(v.accessibilityNeeds) ? v.accessibilityNeeds : [],
                        avoidCategories: Array.isArray(v.avoidCategories) ? v.avoidCategories : [],
                        dailyBudget: (v.dailyBudget !== undefined && v.dailyBudget !== null) ? parseFloat(v.dailyBudget) : null,
                        budgetCurrency: v.budgetCurrency || null,
                        splurgeCategories: Array.isArray(v.splurgeCategories) ? v.splurgeCategories : [],
                        preferredLanguage: v.preferredLanguage || null,
                        spokenLanguages: Array.isArray(v.spokenLanguages) ? v.spokenLanguages : []
                    };
                    updatePrefsMutation.mutate(payload);
                }}
            >
                {/* --- Travel Style & Activity --- */}
                <Divider orientation="left" style={{ fontSize: 13, fontWeight: 700, color: "#6b7280" }}>
                    <CompassOutlined /> Travel Style
                </Divider>
                <Row gutter={16}>
                    <Col xs={24} sm={12}>
                        <Form.Item label="Travel Style" name="travelStyle">
                            <Select style={{ borderRadius: 12 }} placeholder="Select" allowClear>
                                <Option value="RELAXATION">Relaxation</Option>
                                <Option value="ADVENTURE">Adventure</Option>
                                <Option value="LUXURY">Luxury</Option>
                                <Option value="BACKPACKER">Backpacker</Option>
                                <Option value="CULTURAL">Cultural</Option>
                                <Option value="NIGHTLIFE">Nightlife</Option>
                                <Option value="FAMILY">Family</Option>
                                <Option value="ROMANTIC">Romantic</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                    <Col xs={24} sm={12}>
                        <Form.Item label="Activity Level" name="activityLevel">
                            <Select style={{ borderRadius: 12 }} placeholder="Select" allowClear>
                                <Option value="LOW">Low</Option>
                                <Option value="MODERATE">Moderate</Option>
                                <Option value="HIGH">High</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item label="Favorite Categories" name="favoriteCategories">
                    <Select
                        mode="tags"
                        placeholder="e.g. museum, park, cafe"
                        style={{ borderRadius: 12 }}
                        notFoundContent={<div style={{ padding: '8px 12px', color: '#8e8e93', fontSize: 13 }}>Type and press Enter to add</div>}
                    />
                </Form.Item>

                <Form.Item label="Cuisine Preferences" name="cuisinePreferences">
                    <Select
                        mode="tags"
                        placeholder="e.g. turkish, italian, japanese"
                        style={{ borderRadius: 12 }}
                        notFoundContent={<div style={{ padding: '8px 12px', color: '#8e8e93', fontSize: 13 }}>Type and press Enter to add</div>}
                    />
                </Form.Item>

                {/* --- Trip Preferences --- */}
                <Divider orientation="left" style={{ fontSize: 13, fontWeight: 700, color: "#6b7280" }}>
                    <GlobalOutlined /> Trip Preferences
                </Divider>
                <Row gutter={16}>
                    <Col xs={24} sm={12}>
                        <Form.Item label="Preferred Climate" name="preferredClimate">
                            <Select style={{ borderRadius: 12 }} placeholder="Select" allowClear>
                                <Option value="TROPICAL">Tropical</Option>
                                <Option value="TEMPERATE">Temperate</Option>
                                <Option value="COLD">Cold</Option>
                                <Option value="DESERT">Desert</Option>
                                <Option value="ANY">Any</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                    <Col xs={24} sm={12}>
                        <Form.Item label="Trip Pace" name="tripPace">
                            <Select style={{ borderRadius: 12 }} placeholder="Select" allowClear>
                                <Option value="SLOW">Slow</Option>
                                <Option value="MODERATE">Moderate</Option>
                                <Option value="FAST">Fast</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Row gutter={16}>
                    <Col xs={24} sm={12}>
                        <Form.Item label="Accommodation" name="accommodationType">
                            <Select style={{ borderRadius: 12 }} placeholder="Select" allowClear>
                                <Option value="HOTEL">Hotel</Option>
                                <Option value="HOSTEL">Hostel</Option>
                                <Option value="APARTMENT">Apartment</Option>
                                <Option value="RESORT">Resort</Option>
                                <Option value="BOUTIQUE">Boutique</Option>
                                <Option value="ANY">Any</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                    <Col xs={24} sm={12}>
                        <Form.Item label="Transport" name="transportPreference">
                            <Select style={{ borderRadius: 12 }} placeholder="Select" allowClear>
                                <Option value="WALKING">Walking</Option>
                                <Option value="PUBLIC_TRANSPORT">Public Transport</Option>
                                <Option value="CAR_RENTAL">Car Rental</Option>
                                <Option value="TAXI">Taxi</Option>
                                <Option value="ANY">Any</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                {/* --- Budget --- */}
                <Divider orientation="left" style={{ fontSize: 13, fontWeight: 700, color: "#6b7280" }}>
                    💰 Budget
                </Divider>
                <Row gutter={16}>
                    <Col xs={24} sm={14}>
                        <Form.Item label="Daily Budget" name="dailyBudget">
                            <InputNumber min={0} style={{ width: '100%', borderRadius: 12 }} placeholder="e.g. 150" />
                        </Form.Item>
                    </Col>
                    <Col xs={24} sm={10}>
                        <Form.Item label="Currency" name="budgetCurrency">
                            <Select style={{ borderRadius: 12 }} placeholder="Select" allowClear>
                                <Option value="EUR">EUR</Option>
                                <Option value="USD">USD</Option>
                                <Option value="TRY">TRY</Option>
                                <Option value="GBP">GBP</Option>
                            </Select>
                        </Form.Item>
                    </Col>
                </Row>

                <Form.Item label="Splurge Categories" name="splurgeCategories">
                    <Select
                        mode="tags"
                        placeholder="Categories you'll spend more on"
                        style={{ borderRadius: 12 }}
                        notFoundContent={<div style={{ padding: '8px 12px', color: '#8e8e93', fontSize: 13 }}>Type and press Enter to add</div>}
                    />
                </Form.Item>

                {/* --- Constraints & Accessibility --- */}
                <Divider orientation="left" style={{ fontSize: 13, fontWeight: 700, color: "#6b7280" }}>
                    ⚠️ Constraints & Accessibility
                </Divider>

                <Form.Item label="Dietary Restrictions / Allergens" name="dietaryRestrictions">
                    <Select
                        mode="tags"
                        placeholder="e.g. gluten, peanuts, vegan"
                        style={{ borderRadius: 12 }}
                        notFoundContent={<div style={{ padding: '8px 12px', color: '#8e8e93', fontSize: 13 }}>Type and press Enter to add</div>}
                    />
                </Form.Item>

                <Form.Item label="Accessibility Needs" name="accessibilityNeeds">
                    <Select
                        mode="tags"
                        placeholder="e.g. wheelchair, elevator"
                        style={{ borderRadius: 12 }}
                        notFoundContent={<div style={{ padding: '8px 12px', color: '#8e8e93', fontSize: 13 }}>Type and press Enter to add</div>}
                    />
                </Form.Item>

                <Form.Item label="Avoid Categories" name="avoidCategories">
                    <Select
                        mode="tags"
                        placeholder="e.g. nightclub"
                        style={{ borderRadius: 12 }}
                        notFoundContent={<div style={{ padding: '8px 12px', color: '#8e8e93', fontSize: 13 }}>Type and press Enter to add</div>}
                    />
                </Form.Item>

                {/* --- Language --- */}
                <Divider orientation="left" style={{ fontSize: 13, fontWeight: 700, color: "#6b7280" }}>
                    🌐 Language
                </Divider>

                <Form.Item label="Preferred Language" name="preferredLanguage">
                    <Input placeholder="e.g. en" style={{ borderRadius: 12 }} />
                </Form.Item>

                <Form.Item label="Spoken Languages" name="spokenLanguages">
                    <Select
                        mode="tags"
                        placeholder="e.g. tr, en, de"
                        style={{ borderRadius: 12 }}
                        notFoundContent={<div style={{ padding: '8px 12px', color: '#8e8e93', fontSize: 13 }}>Type and press Enter to add</div>}
                    />
                </Form.Item>

                <Button
                    type="primary"
                    htmlType="submit"
                    block
                    icon={<SaveOutlined />}
                    loading={updatePrefsMutation.isPending}
                    style={{
                        height: 48, borderRadius: 16, marginTop: 12,
                        background: "linear-gradient(135deg, #4ade80 0%, #22c55e 100%)",
                        border: "none", fontWeight: 700
                    }}
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
            width={480}
            centered
            closeIcon={true}
            styles={{ body: { padding: "0", background: "#f8f9fa" } }}
            style={{ borderRadius: "32px", overflow: "hidden", maxWidth: "95vw" }}
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
                
                @media (max-width: 480px) {
                    .profile-header-area {
                        flex-direction: column;
                        text-align: center;
                    }
                    .profile-header-meta {
                        justify-content: center;
                    }
                    .profile-stat-box {
                        padding: 10px 8px !important;
                    }
                }
            `}</style>
        </Modal>
    );
};

export default ProfileModal;

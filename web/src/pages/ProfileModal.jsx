import React, { useState, useEffect, useMemo } from "react";
import {
    Modal, Avatar, Typography, Tag, Spin, Progress,
    Form, Input, Select, DatePicker, InputNumber, Button,
    Row, Col, Divider, message, Empty, Checkbox, Badge as AntBadge, ConfigProvider
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
    LogoutOutlined,
    CloseOutlined,
    CameraFilled,
    SearchOutlined,
    UpOutlined,
    DownOutlined,
    ControlOutlined,
    RocketOutlined,
    CoffeeOutlined,
    ShopOutlined
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";
import { useQueryClient, useMutation } from "@tanstack/react-query";
import { useUserPreferences } from "../hooks/useUserPreferences";
import { useUserProfile, useUserStats, useUserCheckins, useProfilePhoto } from "../hooks/useUserProfileData";
import { useGamificationProfile } from "../gamification/useGamificationProfile";
import { userApi } from "../api/userApi";

import dayjs from "dayjs";

const { Title, Text } = Typography;
const { Option } = Select;

const BADGE_ICON_MAP = {
    first_step: <EnvironmentOutlined />,
    foodie: <CoffeeOutlined />,
    speed: <RocketOutlined />,
    culture: <StarOutlined />,
    nature: <ThunderboltOutlined />,
    explorer: <CompassOutlined />,
    photographer: <CameraFilled />,
    adventurer: <FireOutlined />,
    social: <UserOutlined />,
    night_owl: <StarOutlined />,
    early_bird: <CoffeeOutlined />,
    globetrotter: <GlobalOutlined />,
    collector: <ShopOutlined />,
    historian: <StarOutlined />,
    art_lover: <HeartOutlined />,
};

function getBadgeIcon(key) {
    return BADGE_ICON_MAP[key] || <TrophyOutlined />;
}

function formatDate(dateStr) {
    if (!dateStr) return "—";
    return new Date(dateStr).toLocaleDateString("en-US", {
        year: "numeric", month: "short", day: "numeric"
    });
}

// --- Reusable mini components ---

const AccountListItem = ({ icon, label, onClick, color = "#1c1c1e", bgColor = "#f3f4f6", isLast }) => (
    <div
        onClick={onClick}
        className="vivid-interactive"
        style={{
            display: "flex", alignItems: "center", gap: 14, padding: "12px 10px",
            borderBottom: isLast ? "none" : "1px solid rgba(255,255,255,0.05)", cursor: "pointer",
            borderRadius: 14,
            transition: "all 0.2s cubic-bezier(0.4, 0, 0.2, 1)"
        }}
    >
        <div style={{
            width: 38,
            height: 38,
            borderRadius: 11,
            background: bgColor,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
            border: "1px solid rgba(0,0,0,0.03)"
        }}>
            {React.cloneElement(icon, { style: { fontSize: 18, color: color } })}
        </div>
        <span style={{
            flex: 1,
            fontSize: 15,
            fontWeight: 800,
            color: color === "#ff3b30" ? "#ff3b30" : (color.includes("var") ? color : "var(--card-text)"),
            letterSpacing: "-0.2px"
        }}>{label}</span>
        <RightOutlined style={{ fontSize: 12, color: "var(--card-subtext)", opacity: 0.5 }} />
    </div>
);

const GrabHandle = () => (
    <div style={{ display: "flex", justifyContent: "center", padding: "12px 0 16px" }}>
        <div style={{ width: 40, height: 4, background: "var(--card-border, #e5e7eb)", borderRadius: 2 }} />
    </div>
);

const SectionCard = ({ title, subtitle, children, icon, iconBg, onClick }) => (
    <div
        className={`profile-section-card ${onClick ? 'vivid-interactive' : ''}`}
        onClick={onClick}
        style={{
            background: "var(--card-bg, #fff)",
            borderRadius: 24,
            padding: 24,
            marginBottom: 16,
            border: "1px solid var(--card-border, #f1f3f5)",
            cursor: onClick ? "pointer" : "default",
            boxShadow: "0 4px 12px rgba(0,0,0,0.03)"
        }}
    >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: children ? 20 : 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
                {icon && (
                    <div style={{
                        width: 44, height: 44, borderRadius: 12,
                        background: iconBg.startsWith("var") ? `rgba(var(--vivid-blue-rgb, 0,150,255), 0.12)` : iconBg,
                        display: "flex", alignItems: "center", justifyContent: "center",
                        flexShrink: 0,
                        border: `1px solid ${iconBg.startsWith("var") ? 'rgba(0,0,0,0.05)' : 'transparent'}`
                    }}>
                        {React.cloneElement(icon, { style: { fontSize: 20, color: iconBg.startsWith("var") ? "var(--vivid-blue, #0096FF)" : "#fff" } })}
                    </div>
                )}
                <div>
                    <div style={{ fontSize: 18, fontWeight: 850, color: "var(--card-text, #2c3e50)", letterSpacing: "-0.3px" }}>{title}</div>
                    {subtitle && <div style={{ fontSize: 14, color: "var(--card-subtext, #8e8e93)", fontWeight: 600, marginTop: 2, opacity: 0.8 }}>{subtitle}</div>}
                </div>
            </div>
            {onClick && <RightOutlined style={{ fontSize: 14, color: "var(--card-subtext, #8e8e93)", opacity: 0.5 }} />}
        </div>
        {children}
    </div>
);

const ProfileAvatarWithBinary = ({ imageUrl, hasProfilePhoto, size = 100 }) => {
    const { data: binaryPhotoUrl } = useProfilePhoto(hasProfilePhoto);
    const finalImageUrl = binaryPhotoUrl || imageUrl;

    return (
        <Avatar
            size={size}
            src={finalImageUrl}
            icon={!finalImageUrl && <UserOutlined />}
            style={{
                border: "3px solid rgba(255,255,255,0.1)",
                background: "rgba(255,255,255,0.05)",
                boxShadow: size > 50 ? "0 12px 30px rgba(0,0,0,0.3)" : "none"
            }}
        />
    );
};

const ProfileCharacterCard = ({ name, role, level, xp, progress, imageUrl, hasProfilePhoto }) => {
    return (
        <div style={{
            background: "var(--card-bg, #fff)",
            borderRadius: 24,
            padding: "24px",
            marginBottom: 24,
            position: "relative",
            border: "1px solid var(--card-border, #f1f3f5)"
        }}>
            <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
                <div style={{ position: "relative" }}>
                    <div style={{
                        width: 72, height: 72, padding: 3, borderRadius: "50%",
                        background: "linear-gradient(135deg, #0cebeb 0%, #20e3b2 50%, #29ffc6 100%)",
                        boxShadow: "0 8px 24px rgba(0,0,0,0.08)"
                    }}>
                        <div style={{
                            width: "100%", height: "100%", borderRadius: "50%",
                            border: "2px solid var(--card-bg, white)", overflow: "hidden", background: "rgba(128,128,128,0.1)",
                            display: "flex", alignItems: "center", justifyContent: "center"
                        }}>
                            <ProfileAvatarWithBinary imageUrl={imageUrl} hasProfilePhoto={hasProfilePhoto} size={64} />
                        </div>
                    </div>
                    <div style={{
                        position: "absolute", bottom: -2, right: -2,
                        width: 24, height: 24, borderRadius: "50%",
                        background: "#ffcc00", color: "#fff",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        fontSize: 10, fontWeight: 900, border: "2px solid var(--card-bg, white)",
                        boxShadow: "0 4px 8px rgba(0,0,0,0.1)"
                    }}>{level}</div>
                </div>

                <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 19, fontWeight: 850, color: "var(--card-text, #2c3e50)" }}>{name}</div>
                    <div style={{
                        display: "inline-block", padding: "4px 12px", borderRadius: 20,
                        background: "var(--card-bg, #fff)", border: "1px solid var(--card-border, #f1f3f5)",
                        fontSize: 13, color: "#5F7A8F", marginTop: 4, fontWeight: 700
                    }}>
                        {role || "—"}
                    </div>
                    <div style={{
                        fontSize: 13, fontWeight: 800, color: "var(--vivid-blue, #0096FF)", marginTop: 8
                    }}>
                        Level {level} • {new Intl.NumberFormat().format(xp)} XP
                    </div>
                </div>
            </div>
        </div>
    );
};



const InfoRow = ({ label, value }) => (
    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12, alignItems: "flex-start", gap: 12 }}>
        <span style={{ fontSize: 14, color: "var(--card-subtext, #9ca3af)", fontWeight: 700, whiteSpace: "nowrap" }}>{label}</span>
        <span style={{
            fontSize: 15,
            color: "var(--card-text, #1c1c1e)",
            fontWeight: 800,
            textAlign: "right",
            maxWidth: "70%",
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap"
        }} title={value}>{value || "—"}</span>
    </div>
);

const CheckinItem = ({ name, category, date }) => (
    <div style={{
        display: "flex", alignItems: "center", gap: 12, padding: "12px 0",
        borderBottom: "1px solid var(--card-border, #f3f4f6)"
    }}>
        <div style={{ width: 40, height: 40, borderRadius: 12, background: "var(--card-border, rgba(128,128,128,0.1))", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <EnvironmentOutlined style={{ color: "#0096FF" }} />
        </div>
        <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 800, color: "var(--card-text, #1c1c1e)" }}>{name}</div>
            <div style={{ fontSize: 13, color: "var(--card-subtext, #9ca3af)", fontWeight: 600 }}>{category}</div>
        </div>
        <div style={{ fontSize: 13, color: "var(--card-subtext, #9ca3af)", fontWeight: 700 }}>
            {formatDate(date)}
        </div>
    </div>
);

// --- Sub-Views (Stable Components) ---

const MainView = ({ profile, gamification, stats, checkins, user, setView, onClose, isDarkMode = true }) => (
    <div style={{ background: "var(--bg-main, #0D1526)", flex: 1, overflowY: "auto", paddingBottom: 40, borderRadius: 40 }}>
        <div style={{
            padding: "0 24px",
            position: "sticky",
            top: 0,
            zIndex: 10,
            background: "var(--bg-main, #0D1526)",
            paddingBottom: "12px",
            borderBottom: "1px solid transparent"
        }}>
            <GrabHandle />
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24, marginTop: 12 }}>
                <div style={{ fontSize: 24, fontWeight: 900, color: "var(--text-main, #FFFFFF)", letterSpacing: "-0.5px" }}>Profile</div>
                <Button
                    icon={<CloseOutlined style={{ fontSize: 14 }} />}
                    type="text"
                    style={{
                        color: "var(--card-text)", padding: 0, width: 36, height: 36,
                        borderRadius: "50%", background: "var(--card-border, rgba(128,128,128,0.1))",
                        display: "flex", alignItems: "center", justifyContent: "center"
                    }}
                    onClick={onClose}
                />
            </div>
        </div>

        <div style={{ padding: "12px 24px 40px" }}>
            <ProfileCharacterCard
                name={profile?.preferredName || profile?.firstName || profile?.displayName || user?.displayName || "—"}
                role={gamification?.roleText || "—"}
                level={gamification?.levelText ? parseInt(gamification.levelText.replace(/\D/g, ''), 10) : 1}
                xp={gamification?.totalXp || 0}
                progress={gamification?.xpProgressPercent || 0}
                imageUrl={profile?.profileImageUrl || user?.photoURL}
                hasProfilePhoto={profile?.hasProfilePhoto}
            />


            <SectionCard
                title="Edit Profile"
                subtitle="Update your personal information"
                icon={<ControlOutlined />}
                iconBg="var(--vivid-blue, #38BDF8)"
                onClick={() => setView('EDIT_PROFILE')}
            />

            <SectionCard
                title="Account Details"
                icon={<UserOutlined />}
                iconBg="var(--vivid-blue, #0096FF)"
            >
                <div style={{ padding: "12px 16px 4px" }}>
                    <InfoRow label="Email" value={profile?.email || user?.email} />
                    <InfoRow
                        label="Joined"
                        value={profile?.createdAt || user?.metadata?.creationTime
                            ? dayjs(profile?.createdAt || user?.metadata?.creationTime).format('MMMM D, YYYY')
                            : "—"}
                    />
                    <InfoRow label="Country" value={profile?.country} />
                    <InfoRow label="Gender" value={profile?.gender ? (profile.gender.replace(/_/g, ' ').charAt(0).toUpperCase() + profile.gender.replace(/_/g, ' ').slice(1).toLowerCase()) : null} />
                </div>
            </SectionCard>

            <SectionCard
                title="Check-in History"
                subtitle="Places you've visited"
                icon={<ClockCircleOutlined />}
                iconBg="var(--vivid-coral, #FF6B6B)"
            >
                <div style={{ display: "flex", flexDirection: "column", gap: 0, marginTop: 8, minHeight: checkins?.length > 0 ? 'auto' : 160, justifyContent: "center" }}>
                    {checkins?.length > 0 ? (
                        checkins.slice(0, 3).map((item, idx) => (
                            <CheckinItem key={item.checkInId || idx} name={item.poiName} category={item.category} date={item.checkedInAt} />
                        ))
                    ) : (
                        <div style={{ textAlign: "center", padding: "32px 0", color: "var(--card-subtext, #9ca3af)", fontSize: 14, fontWeight: 600, display: "flex", flexDirection: "column", alignItems: "center", justifyItems: "center", gap: 8 }}>
                            <EnvironmentOutlined style={{ opacity: 0.5, fontSize: 32 }} />
                            No check-ins yet
                        </div>
                    )}
                </div>
            </SectionCard>

            <SectionCard
                title="Travel Statistics"
                subtitle="Your journey so far"
                icon={<BarChartOutlined />}
                iconBg="var(--vivid-teal, #00B4D8)"
            >
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 12 }}>
                    <div style={{ background: "var(--card-bg, rgba(128,128,128,0.06))", borderRadius: 20, padding: 16, minHeight: 88, display: "flex", flexDirection: "column", justifyContent: "center" }}>
                        <div style={{ fontSize: 20, fontWeight: 900, color: "var(--card-text, #1c1c1e)" }}>{stats?.visitedPoisCount || 0}</div>
                        <div style={{ fontSize: 12, color: "var(--card-subtext, #9ca3af)", fontWeight: 700, marginTop: 4 }}>Total places visited</div>
                    </div>
                    <div style={{ background: "var(--card-bg, rgba(128,128,128,0.06))", borderRadius: 20, padding: 16, minHeight: 88, display: "flex", flexDirection: "column", justifyContent: "center" }}>
                        <div style={{ fontSize: 15, fontWeight: 800, color: "var(--card-text, #1c1c1e)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{stats?.lastVisitPoiName || "—"}</div>
                        <div style={{ fontSize: 12, color: "var(--card-subtext, #9ca3af)", fontWeight: 700, marginTop: 4, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{stats?.lastVisitDate ? dayjs(stats.lastVisitDate).format('MMM D, YYYY') : "—"}</div>
                    </div>
                    <div style={{ background: "var(--card-bg, rgba(128,128,128,0.06))", borderRadius: 20, padding: 16, minHeight: 88, display: "flex", flexDirection: "column", justifyContent: "center" }}>
                        <div style={{ fontSize: 15, fontWeight: 800, color: "var(--card-text, #1c1c1e)", textTransform: "capitalize", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{stats?.favoriteCategory || "—"}</div>
                        <div style={{ fontSize: 12, color: "var(--card-subtext, #9ca3af)", fontWeight: 700, marginTop: 4 }}>Favorite category</div>
                    </div>
                    <div style={{ background: "var(--card-bg, rgba(128,128,128,0.06))", borderRadius: 20, padding: 16, minHeight: 88, display: "flex", flexDirection: "column", justifyContent: "center" }}>
                        <div style={{ fontSize: 20, fontWeight: 900, color: "var(--card-text, #1c1c1e)" }}>{stats?.distinctCategoriesCount || 0}</div>
                        <div style={{ fontSize: 12, color: "var(--card-subtext, #9ca3af)", fontWeight: 700, marginTop: 4 }}>Categories explored</div>
                    </div>
                </div>
            </SectionCard>

            <SectionCard
                title="Achievements"
                subtitle="XP, badges, and challenges"
                icon={<TrophyOutlined />}
                iconBg="var(--vivid-amber, #FFB347)"
                onClick={() => setView('GAMIFICATION')}
            />
        </div>
    </div>
);

const GamificationView = ({ gamification, setView, onClose, isDarkMode = true }) => {
    const levelNum = gamification?.levelText ? parseInt(gamification.levelText.replace(/\D/g, ''), 10) : 1;
    return (
        <div style={{ background: "var(--bg-main, #0D1526)", flex: 1, overflowY: "auto", paddingBottom: 40, borderRadius: 40 }}>
            <div style={{
                padding: "0 24px",
                position: "sticky",
                top: 0,
                zIndex: 10,
                background: "var(--bg-main, #0D1526)",
                paddingBottom: "12px",
                borderBottom: "1px solid var(--card-border, #FFFFFF)"
            }}>
                <GrabHandle />
                <div style={{ display: "flex", alignItems: "center", position: "relative", marginBottom: 24, marginTop: 12 }}>
                    <Button
                        icon={<ArrowLeftOutlined />}
                        type="text"
                        style={{ position: "absolute", left: -8, fontSize: 18, color: "var(--card-text, #1c1c1e)" }}
                        onClick={() => setView('MAIN')}
                    />
                    <div style={{ flex: 1, textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center" }}>
                        <div style={{ fontSize: 12, fontWeight: 900, color: "var(--vivid-blue, #0096FF)", textTransform: "uppercase", letterSpacing: "1px", marginBottom: 2 }}>
                            Experience
                        </div>
                        <div style={{ fontSize: 19, fontWeight: 900, color: "var(--card-text, #1c1c1e)", letterSpacing: "-0.5px" }}>Level & Badges</div>
                    </div>
                    <Button
                        icon={<CloseOutlined style={{ fontSize: 14 }} />}
                        type="text"
                        style={{
                            position: "absolute", right: -8, color: "var(--card-text)", padding: 0, width: 36, height: 36,
                            borderRadius: "50%", background: "var(--card-border, rgba(128,128,128,0.1))",
                            display: "flex", alignItems: "center", justifyContent: "center"
                        }}
                        onClick={onClose}
                    />
                </div>
            </div>

            <div style={{ padding: "24px 24px 40px" }}>
                <div style={{ background: "var(--card-bg, #fff)", borderRadius: 28, padding: "24px 16px 20px", boxShadow: "0 8px 32px rgba(0,0,0,0.1)", border: "1px solid var(--card-border, #f1f3f5)", textAlign: "center", marginBottom: 24 }}>
                    <div style={{ display: "flex", justifyContent: "center", marginBottom: 20 }}>
                        <Progress
                            type="circle"
                            percent={gamification?.xpProgressPercent || 0}
                            size={140}
                            strokeWidth={8}
                            strokeColor={{ '0%': '#0cebeb', '100%': '#20e3b2' }}
                            format={(percent) => (
                                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                                    <div style={{ fontSize: 28, fontWeight: 900, color: "var(--card-text, #1c1c1e)", lineHeight: 1 }}>{percent}%</div>
                                    <div style={{ fontSize: 11, fontWeight: 600, color: "var(--card-subtext, #9ca3af)", marginTop: 4 }}>to Level {levelNum + 1}</div>
                                    <div style={{ fontSize: 15, fontWeight: 800, color: "var(--card-text, #1c1c1e)", marginTop: 6 }}>{new Intl.NumberFormat().format(gamification?.totalXp || 0)} XP</div>
                                </div>
                            )}
                        />
                    </div>

                    <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", borderTop: "1px solid var(--card-border, #f1f3f5)", paddingTop: 16 }}>
                        {gamification?.stats?.slice(0, 3).map((s, idx) => (
                            <div key={s.label} style={{
                                textAlign: "center",
                                borderRight: idx < 2 ? "1px solid var(--card-border, #f1f3f5)" : "none"
                            }}>
                                <div style={{ fontSize: 28, fontWeight: 900, color: "var(--card-text, #1c1c1e)" }}>{s.value}</div>
                                <div style={{ fontSize: 12, fontWeight: 600, color: "var(--card-subtext, #9ca3af)", marginTop: 4, textTransform: "capitalize" }}>{s.label}</div>
                            </div>
                        ))}
                    </div>
                </div>

                <div style={{ fontSize: 15, fontWeight: 800, color: "var(--card-text, #1c1c1e)", marginBottom: 16 }}>Achievement Badges</div>

                <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
                    {gamification?.badges?.map((badge, i) => {
                        const colors = ["#fb923c", "#ef4444", "#0ea5e9", "#22c55e", "#d946ef", "#a855f7"];
                        const bgColor = colors[i % colors.length];

                        return (
                            <div key={badge.id} style={{
                                background: "var(--card-bg, #fff)", borderRadius: 20, padding: "20px 8px", textAlign: "center",
                                boxShadow: badge.earned ? `0 8px 24px ${bgColor}25` : "0 4px 12px rgba(0,0,0,0.02)",
                                border: `1px solid ${badge.earned ? bgColor + '40' : 'var(--card-border, transparent)'}`,
                                transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
                                filter: badge.earned ? "none" : "grayscale(100%) brightness(0.8)",
                                opacity: badge.earned ? 1 : 0.6
                            }}>
                                <div style={{
                                    width: 56, height: 56, background: badge.earned ? bgColor : "var(--card-border, #f3f4f6)",
                                    borderRadius: '50%', display: "flex", alignItems: "center", justifyContent: "center",
                                    margin: "0 auto 12px", fontSize: 24, color: "#fff",
                                    boxShadow: badge.earned ? `0 8px 16px ${bgColor}50` : "none"
                                }}>
                                    {getBadgeIcon(badge.key)}
                                </div>
                                <div style={{ fontSize: 12, fontWeight: 900, color: badge.earned ? "var(--card-text)" : "var(--card-subtext)", letterSpacing: "-0.2px" }}>{badge.title}</div>
                                {badge.earned && <div style={{ color: "var(--vivid-green)", fontSize: 14, fontWeight: 900, marginTop: 4 }}>Completed</div>}
                            </div>
                        );
                    })}
                </div>
            </div>
        </div>
    );
};



const GenderSelector = ({ value, onChange, isDarkMode = true }) => {
    const options = [
        { label: "Male", value: "MALE" },
        { label: "Female", value: "FEMALE" },
        { label: "Other", value: "OTHER" },
        { label: "Prefer not to say", value: "PREFER_NOT_TO_SAY" }
    ];
    return (
        <ConfigProvider
            theme={{
                token: {
                    colorBgContainer: 'transparent',
                    colorText: 'var(--text-main, #FFFFFF)',
                    colorTextPlaceholder: 'rgba(255,255,255,0.5)',
                    colorPrimary: '#38BDF8',
                    colorBgElevated: isDarkMode ? '#1A2333' : '#FFFFFF',
                    colorIcon: 'var(--text-sub)',
                }
            }}
        >
            <div style={{ border: "2px solid var(--card-border, rgba(255,255,255,0.1))", borderRadius: 16, background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))" }}>
                <Select
                    value={value ? String(value).toUpperCase() : undefined}
                    onChange={onChange}
                    placeholder="Select gender"
                    style={{ width: "100%", height: 56 }}
                    variant="borderless"
                    getPopupContainer={(trigger) => trigger.parentNode}
                    options={options}
                />
            </div>
        </ConfigProvider>
    );
};

const EditProfileView = ({ profile, user, setView, onClose, updateMutation, isDarkMode = true }) => {
    const [form] = Form.useForm();
    const [showAdditionalInfo, setShowAdditionalInfo] = useState(false);
    const queryClient = useQueryClient();


    useEffect(() => {
        if (profile || user) {
            form.setFieldsValue({
                firstName: profile?.firstName,
                middleName: profile?.middleName,
                lastName: profile?.lastName,
                preferredName: profile?.preferredName,
                country: profile?.country,
                birthDate: profile?.birthDate ? dayjs(profile.birthDate) : null,
                gender: profile?.gender || ""
            });
        }
    }, [profile, user, form]);

    return (
        <div style={{ background: "var(--bg-main, #0D1526)", flex: 1, display: "flex", flexDirection: "column", overflow: "hidden", borderRadius: 40 }}>
            {/* STICKY HEADER */}
            <div style={{
                padding: "0 24px",
                position: "sticky",
                top: 0,
                zIndex: 10,
                background: "var(--bg-main, #0D1526)",
                paddingBottom: "12px",
                borderBottom: "1px solid var(--card-border, rgba(255,255,255,0.1))"
            }}>
                <GrabHandle />
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24, marginTop: 12 }}>
                    <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                        <Button
                            icon={<ArrowLeftOutlined />}
                            type="text"
                            style={{ fontSize: 18, color: "var(--text-main, #FFFFFF)", padding: 0 }}
                            onClick={() => setView('MAIN')}
                        />
                        <div>
                            <div style={{ fontSize: 10, fontWeight: 900, color: "var(--vivid-blue, #38BDF8)", textTransform: "uppercase", letterSpacing: "1px" }}>Details</div>
                            <div style={{ fontSize: 19, fontWeight: 900, color: "var(--text-main, #FFFFFF)", letterSpacing: "-0.5px" }}>Edit Profile</div>
                        </div>
                    </div>
                    <Button
                        icon={<CloseOutlined style={{ fontSize: 14 }} />}
                        type="text"
                        style={{
                            color: "var(--card-text)", padding: 0, width: 36, height: 36,
                            borderRadius: "50%", background: "var(--card-border, rgba(128,128,128,0.1))",
                            display: "flex", alignItems: "center", justifyContent: "center"
                        }}
                        onClick={onClose}
                    />
                </div>
            </div>

            {/* SCROLLABLE BODY */}
            <div style={{ flex: 1, overflowY: "auto", padding: "12px 24px 24px" }}>
                <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginBottom: 32 }}>
                    <div style={{ position: "relative" }}>
                        <ProfileAvatarWithBinary
                            imageUrl={profile?.profileImageUrl || user?.photoURL}
                            hasProfilePhoto={profile?.hasProfilePhoto}
                        />
                        <div
                            style={{
                                position: "absolute", bottom: 2, right: 2, width: 32, height: 32,
                                background: "#38BDF8", borderRadius: "50%", border: "3px solid #0D1526",
                                display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer"
                            }}
                            onClick={() => document.getElementById('profile-photo-upload').click()}
                        >
                            <CameraFilled style={{ color: "#fff", fontSize: 14 }} />
                        </div>
                        <input
                            type="file"
                            id="profile-photo-upload"
                            style={{ display: 'none' }}
                            accept="image/*"
                            onChange={async (e) => {
                                const file = e.target.files[0];
                                if (file) {
                                    if (file.size > 2 * 1024 * 1024) {
                                        message.error("File too large — max 2 MB allowed");
                                        return;
                                    }
                                    try {
                                        const hide = message.loading("Uploading photo...", 0);
                                        await userApi.uploadProfilePhoto(file);
                                        hide();
                                        message.success("Profile photo updated");
                                        // Refresh profile and photo queries
                                        queryClient.invalidateQueries(["user", "profile"]);
                                        queryClient.invalidateQueries(["user", "photo"]);

                                    } catch (err) {
                                        message.error(err.friendlyMessage || "Upload failed");
                                    }
                                }
                            }}
                        />
                    </div>
                    {profile?.hasProfilePhoto && (
                        <Button
                            type="link"
                            danger
                            size="small"
                            style={{ marginTop: 12, fontWeight: 700 }}
                            onClick={async () => {
                                try {
                                    await userApi.deleteProfilePhoto();
                                    message.success("Profile photo deleted");
                                    queryClient.invalidateQueries(["user", "profile"]);
                                    queryClient.invalidateQueries(["user", "photo"]);
                                } catch (err) {

                                    message.error("Failed to delete photo");
                                }
                            }}
                        >
                            Remove Photo
                        </Button>
                    )}
                </div>


                <div style={{
                    background: "var(--vivid-subtle-bg, rgba(255,255,255,0.03))",
                    borderRadius: 24,
                    padding: "24px",
                    marginBottom: 32,
                    border: "1px solid var(--card-border, rgba(255,255,255,0.05))"
                }}>
                    <div style={{ display: "flex", gap: 16, marginBottom: 20 }}>
                        <div style={{ width: 36, height: 36, borderRadius: 10, background: "rgba(56, 189, 248, 0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                            <MailOutlined style={{ color: "#38BDF8", fontSize: 18 }} />
                        </div>
                        <div style={{ flex: 1 }}>
                            <div style={{ fontSize: 10, fontWeight: 900, color: "var(--text-sub, rgba(255,255,255,0.4))", letterSpacing: "1px", marginBottom: 2 }}>ACCOUNT EMAIL</div>
                            <div style={{ fontSize: 15, fontWeight: 800, color: "var(--text-main, #FFFFFF)" }}>{profile?.email || user?.email}</div>
                        </div>
                    </div>

                    <div style={{ height: 1, background: "var(--card-border, rgba(255,255,255,0.05))", margin: "0 0 20px 52px" }} />

                    <div style={{ display: "flex", gap: 16, marginBottom: 20 }}>
                        <div style={{ width: 36, height: 36, borderRadius: 10, background: "rgba(16, 185, 129, 0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                            <CalendarOutlined style={{ color: "#10b981", fontSize: 18 }} />
                        </div>
                        <div style={{ flex: 1 }}>
                            <div style={{ fontSize: 10, fontWeight: 900, color: "var(--text-sub, rgba(255,255,255,0.4))", letterSpacing: "1px", marginBottom: 2 }}>MEMBER SINCE</div>
                            <div style={{ fontSize: 15, fontWeight: 800, color: "var(--text-main, #FFFFFF)" }}>
                                {profile?.createdAt || user?.metadata?.creationTime
                                    ? dayjs(profile?.createdAt || user?.metadata?.creationTime).format('MMMM D, YYYY')
                                    : "—"}
                            </div>
                        </div>
                    </div>
                </div>

                <div style={{ fontSize: 12, fontWeight: 900, color: "var(--card-subtext)", letterSpacing: "1.5px", marginBottom: 20, marginLeft: 12, textTransform: "uppercase", display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
                    <span>Personal Info</span>
                    <span style={{ fontSize: 10, fontWeight: 700, color: "rgba(255,255,255,0.4)", textTransform: "none", letterSpacing: "0" }}>
                        <span style={{ color: "#FF6B6B" }}>*</span> indicates a mandatory field
                    </span>
                </div>

                <ConfigProvider theme={{ token: { colorTextPlaceholder: 'rgba(255,255,255,0.5)' } }}>
                    <Form
                        form={form}
                        layout="vertical"
                        initialValues={{
                            ...profile,
                            birthDate: profile?.birthDate ? dayjs(profile.birthDate) : null
                        }}
                        onFinish={(v) => {
                            const cleanedValues = Object.fromEntries(
                                Object.entries(v).map(([key, val]) => [key, val === "" ? null : val])
                            );
                            updateMutation.mutate({
                                ...cleanedValues,
                                birthDate: v.birthDate ? v.birthDate.format('YYYY-MM-DD') : null
                            });
                        }}
                        requiredMark={false}
                    >
                        <Form.Item
                            label={<span style={{ fontSize: 14, fontWeight: 900, color: "var(--text-main, #FFFFFF)", opacity: 0.9 }}>First Name <span style={{ color: "var(--vivid-coral, #FF6B6B)" }}>*</span></span>}
                            name="firstName"
                            rules={[{ required: true, message: "Please enter your first name" }]}
                            style={{ marginBottom: 28 }}
                        >
                            <Input placeholder="Enter your first name" style={{ borderRadius: 16, height: 60, background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))", border: "2px solid var(--card-border, rgba(255,255,255,0.1))", fontSize: 16, fontWeight: 600, color: "var(--text-main, #FFFFFF)" }} />
                        </Form.Item>

                        <Form.Item
                            label={<span style={{ fontSize: 14, fontWeight: 900, color: "var(--text-main, #FFFFFF)", opacity: 0.9 }}>Middle Name</span>}
                            name="middleName"
                            style={{ marginBottom: 28 }}
                        >
                            <Input placeholder="Enter your middle name" style={{ borderRadius: 16, height: 60, background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))", border: "2px solid var(--card-border, rgba(255,255,255,0.1))", fontSize: 16, fontWeight: 600, color: "var(--text-main, #FFFFFF)" }} />
                        </Form.Item>

                        <Form.Item
                            label={<span style={{ fontSize: 14, fontWeight: 900, color: "var(--text-main, #FFFFFF)", opacity: 0.9 }}>Last Name <span style={{ color: "var(--vivid-coral, #FF6B6B)" }}>*</span></span>}
                            name="lastName"
                            rules={[{ required: true, message: "Please enter your last name" }]}
                            style={{ marginBottom: 28 }}
                        >
                            <Input placeholder="Enter your last name" style={{ borderRadius: 16, height: 60, background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))", border: "2px solid var(--card-border, rgba(255,255,255,0.1))", fontSize: 16, fontWeight: 600, color: "var(--text-main, #FFFFFF)" }} />
                        </Form.Item>

                        <Form.Item
                            label={<span style={{ fontSize: 14, fontWeight: 900, color: "var(--text-main, #FFFFFF)", opacity: 0.9 }}>Preferred Name</span>}
                            name="preferredName"
                            style={{ marginBottom: 12 }}
                        >
                            <Input placeholder="How should we call you?" style={{ borderRadius: 16, height: 60, background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))", border: "2px solid var(--card-border, rgba(255,255,255,0.1))", fontSize: 16, fontWeight: 600, color: "var(--text-main, #FFFFFF)" }} />
                        </Form.Item>
                        <div style={{ fontSize: 12, fontWeight: 700, color: "var(--text-sub, rgba(255,255,255,0.4))", marginBottom: 32, paddingLeft: 12 }}>Overrides your display name across the app</div>

                        <Divider style={{ margin: "32px 0", borderColor: "var(--card-border, rgba(255,255,255,0.05))" }} />

                        <div
                            onClick={() => setShowAdditionalInfo(!showAdditionalInfo)}
                            style={{
                                fontSize: 12,
                                fontWeight: 900,
                                color: "var(--card-subtext, rgba(255,255,255,0.4))",
                                letterSpacing: "1.5px",
                                textTransform: "uppercase",
                                marginLeft: 12,
                                marginBottom: 20,
                                display: "flex",
                                justifyContent: "space-between",
                                alignItems: "center",
                                cursor: "pointer",
                                padding: "8px 0"
                            }}
                        >
                            <span>Additional Info</span>
                            <div style={{ display: "flex", alignItems: "center", gap: 6, color: "#38BDF8", fontSize: 11, fontWeight: 800, textTransform: "none", letterSpacing: "0" }}>
                                {showAdditionalInfo ? "Hide" : "Expand"}
                                {showAdditionalInfo ? <UpOutlined style={{ fontSize: 10 }} /> : <DownOutlined style={{ fontSize: 10 }} />}
                            </div>
                        </div>

                        {showAdditionalInfo && (
                            <div style={{ marginBottom: 32 }}>
                                <Form.Item
                                    label={<span style={{ fontSize: 14, fontWeight: 900, color: "var(--text-main, #FFFFFF)", opacity: 0.9 }}>Origin Country</span>}
                                    name="country"
                                    style={{ marginBottom: 28 }}
                                >
                                    <Input
                                        placeholder="Enter origin country"
                                        style={{
                                            borderRadius: 16,
                                            height: 60,
                                            background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))",
                                            border: "2px solid var(--card-border, rgba(255,255,255,0.1))",
                                            fontSize: 16,
                                            fontWeight: 600,
                                            color: "var(--text-main, #FFFFFF)"
                                        }}
                                    />
                                </Form.Item>

                                <div style={{ marginBottom: 28 }}>
                                    <div style={{ fontSize: 14, fontWeight: 900, color: "var(--text-main, #FFFFFF)", opacity: 0.9, marginBottom: 8 }}>Date of Birth</div>
                                    <ConfigProvider
                                        theme={{
                                            token: {
                                                colorBgElevated: isDarkMode ? '#1A2333' : '#FFFFFF',
                                                colorText: isDarkMode ? '#FFFFFF' : '#1A2332',
                                                colorTextPlaceholder: isDarkMode ? 'rgba(255,255,255,0.55)' : 'rgba(0,0,0,0.4)',
                                                colorBorder: 'transparent',
                                                colorPrimary: '#38BDF8',
                                                colorIcon: isDarkMode ? 'rgba(255,255,255,0.4)' : 'rgba(0,0,0,0.4)',
                                                colorTextHeading: isDarkMode ? '#FFFFFF' : '#1A2332',
                                            }
                                        }}
                                    >
                                        <div style={{ border: "2px solid var(--card-border, rgba(255,255,255,0.1))", borderRadius: 16, background: "var(--vivid-subtle-bg, rgba(255,255,255,0.05))" }}>
                                            <Form.Item name="birthDate" noStyle>
                                                <DatePicker
                                                    variant="borderless"
                                                    inputReadOnly={true}
                                                    style={{
                                                        width: "100%",
                                                        height: 56,
                                                        fontSize: 16,
                                                        fontWeight: 600,
                                                        color: "var(--text-main, #FFFFFF)",
                                                        background: "transparent",
                                                        border: "none",
                                                        boxShadow: "none"
                                                    }}
                                                />
                                            </Form.Item>
                                        </div>
                                    </ConfigProvider>
                                </div>

                                <Form.Item
                                    label={<span style={{ fontSize: 14, fontWeight: 900, color: "var(--text-main, #FFFFFF)", opacity: 0.9 }}>Gender Identity</span>}
                                    name="gender"
                                    style={{ marginBottom: 0 }}
                                >
                                    <GenderSelector isDarkMode={isDarkMode} />
                                </Form.Item>
                            </div>
                        )}
                    </Form>
                </ConfigProvider>
            </div>

            {/* FIXED FOOTER */}
            <div style={{ padding: "20px 24px 30px", display: "flex", gap: 12, background: "var(--bg-main, #0D1526)", borderTop: "1px solid var(--card-border, rgba(255,255,255,0.1))", zIndex: 10 }}>
                <Button block size="large" onClick={() => setView('MAIN')} style={{ height: 56, borderRadius: 16, fontSize: 16, fontWeight: 800, color: "var(--text-main, #FFFFFF)", background: "var(--card-border, rgba(255,255,255,0.1))", border: "none" }}>Cancel</Button>
                <Button type="primary" block size="large" onClick={() => form.submit()} loading={updateMutation.isPending} style={{ height: 56, borderRadius: 16, fontSize: 16, fontWeight: 800, background: "var(--vivid-blue, #00B4D8)", border: "none", color: "#fff" }}>Save Changes</Button>
            </div>
        </div>
    );
};

const ProfileModal = ({ open, onClose, user, themeClass, isDarkMode }) => {
    const navigate = useNavigate();
    const queryClient = useQueryClient();
    const [view, setView] = useState('MAIN');

    const { data: profile } = useUserProfile();
    const { data: stats } = useUserStats();
    const { data: checkins } = useUserCheckins();
    const { data: gamification } = useGamificationProfile();

    useEffect(() => {
        if (!open) {
            setTimeout(() => setView('MAIN'), 300);
        }
    }, [open]);

    const updateProfileMutation = useMutation({
        mutationFn: (values) => userApi.updateProfile(values),
        onSuccess: () => {
            queryClient.invalidateQueries(["user", "profile"]);
            message.success("Your profile is all set!");
            setView('MAIN');
        },
        onError: (err) => {
            message.error(err?.friendlyMessage || "Failed to update profile");
        }
    });

    // SCROLL TO TOP WHEN VIEW CHANGES
    useEffect(() => {
        const modalContainer = document.querySelector('.ant-modal-wrap');
        if (modalContainer) {
            modalContainer.scrollTo({ top: 0, behavior: 'instant' });
        }
        const scrollDiv = document.querySelector('.modal-shell');
        if (scrollDiv) {
            scrollDiv.scrollTo({ top: 0, behavior: 'instant' });
        }
    }, [view]);



    return (
        <ConfigProvider
            theme={{
                components: {
                    Modal: {
                        contentBg: 'transparent',
                        headerBg: 'transparent',
                        paddingContentHorizontal: 0,
                        paddingMD: 0,
                        borderRadiusLG: 40,
                        boxShadow: 'none',
                    },
                },
            }}
        >
            <Modal
                open={open}
                onCancel={onClose}
                footer={null}
                closable={false}
                width={480}
                centered
                styles={{
                    body: {
                        height: 750,
                        overflowY: 'auto',
                        padding: 0,
                        display: 'flex',
                        flexDirection: 'column',
                        borderRadius: 40,
                        overscrollBehavior: 'contain'
                    },
                    content: {
                        background: 'transparent',
                        borderRadius: 40,
                        padding: 0,
                        border: 'none',
                        boxShadow: 'none',
                        overflow: 'hidden'
                    }
                }}
                modalRender={(modal) => (
                    <div className="modal-shell">
                        <div className={themeClass} style={{ height: "100%", display: "flex", flexDirection: "column" }}>
                            {modal}
                        </div>
                    </div>
                )}
            >
                {view === 'MAIN' && (
                    <MainView
                        isDarkMode={isDarkMode}
                        profile={profile}
                        gamification={gamification}
                        stats={stats}
                        checkins={checkins}
                        user={user}
                        setView={setView}
                        onClose={onClose}
                    />
                )}
                {view === 'GAMIFICATION' && (
                    <GamificationView
                        isDarkMode={isDarkMode}
                        gamification={gamification}
                        setView={setView}
                        onClose={onClose}
                    />
                )}
                {view === 'EDIT_PROFILE' && (
                    <EditProfileView
                        isDarkMode={isDarkMode}
                        profile={profile}
                        user={user}
                        setView={setView}
                        onClose={onClose}
                        updateMutation={updateProfileMutation}
                    />
                )}
            </Modal>
        </ConfigProvider>
    );
};

export default ProfileModal;

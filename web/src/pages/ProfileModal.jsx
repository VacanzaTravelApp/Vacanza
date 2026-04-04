import React, { useState, useEffect, useMemo } from "react";
import {
    Modal, Avatar, Typography, Tag, Spin, Progress,
    Form, Input, Select, DatePicker, InputNumber, Button,
    Row, Col, Divider, message, Empty, Checkbox, Badge as AntBadge
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
    ControlOutlined
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

// --- Reusable mini components (Mobile-Aligned) ---

const AccountListItem = ({ icon, label, onClick, color = "#1c1c1e", bgColor = "#f3f4f6", isLast }) => (
    <div
        onClick={onClick}
        style={{
            display: "flex", alignItems: "center", gap: 14, padding: "12px 0",
            borderBottom: isLast ? "none" : "1px solid #f8f9fa", cursor: "pointer",
            transition: "all 0.2s ease"
        }}
    >
        <div style={{ width: 36, height: 36, borderRadius: 10, background: bgColor, display: "flex", alignItems: "center", justifyContent: "center" }}>
            {React.cloneElement(icon, { style: { fontSize: 18, color: color } })}
        </div>
        <span style={{ flex: 1, fontSize: 14, fontWeight: 700, color: color === "#ff3b30" ? "#ff3b30" : "#1c1c1e" }}>{label}</span>
        <RightOutlined style={{ fontSize: 10, color: "#d1d5db" }} />
    </div>
);

const GrabHandle = () => (
    <div style={{ display: "flex", justifyContent: "center", padding: "12px 0 16px" }}>
        <div style={{ width: 40, height: 4, background: "#e5e7eb", borderRadius: 2 }} />
    </div>
);

const SectionCard = ({ title, subtitle, children, icon, iconBg, onClick }) => (
    <div
        onClick={onClick}
        style={{
            background: "#fff",
            borderRadius: 24,
            padding: "20px 24px",
            marginBottom: 16,
            boxShadow: "0 4px 20px rgba(0,0,0,0.03)",
            position: "relative",
            cursor: onClick ? "pointer" : "default"
        }}
    >
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: children ? 16 : 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
                {icon && (
                    <div style={{
                        width: 44, height: 44, borderRadius: 12,
                        background: iconBg || "#f3f4f6",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        boxShadow: "0 4px 12px rgba(0,0,0,0.05)"
                    }}>
                        {React.cloneElement(icon, { style: { fontSize: 20, color: "#fff" } })}
                    </div>
                )}
                <div>
                    <div style={{ fontSize: 16, fontWeight: 800, color: "#2c3e50" }}>{title}</div>
                    {subtitle && <div style={{ fontSize: 12, color: "#8e8e93", fontWeight: 500, marginTop: 2 }}>{subtitle}</div>}
                </div>
            </div>
            {onClick && <RightOutlined style={{ fontSize: 12, color: "#c7c7cc" }} />}
        </div>
        {children}
    </div>
);

const ProfileCharacterCard = ({ name, role, level, xp, progress, imageUrl }) => (
    <div style={{
        background: "rgba(0, 150, 255, 0.04)",
        borderRadius: 24,
        padding: "24px",
        marginBottom: 24,
        position: "relative",
        border: "1px solid rgba(0, 150, 255, 0.05)"
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
                        border: "2px solid white", overflow: "hidden", background: "#f3f4f6",
                        display: "flex", alignItems: "center", justifyContent: "center"
                    }}>
                        {imageUrl ? <img src={imageUrl} style={{ width: "100%", height: "100%", objectFit: "cover" }} /> : <UserOutlined style={{ fontSize: 32, color: "#9ca3af" }} />}
                    </div>
                </div>
                <div style={{
                    position: "absolute", bottom: -2, right: -2,
                    width: 24, height: 24, borderRadius: "50%",
                    background: "#ffcc00", color: "#fff",
                    display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: 10, fontWeight: 900, border: "2px solid white",
                    boxShadow: "0 4px 8px rgba(0,0,0,0.1)"
                }}>{level}</div>
            </div>

            <div style={{ flex: 1 }}>
                <div style={{ fontSize: 17, fontWeight: 850, color: "#2c3e50" }}>{name}</div>
                <div style={{
                    display: "inline-block", padding: "2px 10px", borderRadius: 20,
                    background: "#fff", border: "1px solid #f1f3f5",
                    fontSize: 12, color: "#5F7A8F", marginTop: 4, fontWeight: 600
                }}>
                    {role || "—"}
                </div>
                <div style={{
                    fontSize: 12, fontWeight: 800, color: "#0096FF", marginTop: 6
                }}>
                    Level {level} • {new Intl.NumberFormat().format(xp)} XP
                </div>
            </div>
        </div>
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

const StatBox = ({ value, label }) => (
    <div style={{ textAlign: "center", flex: 1 }}>
        <div style={{ fontSize: 18, fontWeight: 900, color: "#1c1c1e" }}>{value}</div>
        <div style={{ fontSize: 10, fontWeight: 700, color: "#9ca3af", textTransform: "uppercase", marginTop: 2, letterSpacing: "0.5px" }}>{label}</div>
    </div>
);

const CheckinItem = ({ name, category, date }) => (
    <div style={{
        display: "flex", alignItems: "center", gap: 12, padding: "12px 0",
        borderBottom: "1px solid #f3f4f6"
    }}>
        <div style={{ width: 40, height: 40, borderRadius: 12, background: "#f3f4f6", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <EnvironmentOutlined style={{ color: "#0096FF" }} />
        </div>
        <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 800, color: "#1c1c1e" }}>{name}</div>
            <div style={{ fontSize: 11, color: "#9ca3af", fontWeight: 600 }}>{category}</div>
        </div>
        <div style={{ fontSize: 12, color: "#9ca3af", fontWeight: 700 }}>
            {formatDate(date)}
        </div>
    </div>
);


const ProfileModal = ({ open, onClose, user }) => {
    const navigate = useNavigate();
    const queryClient = useQueryClient();
    const [view, setView] = useState('MAIN');
    const [pickerField, setPickerField] = useState(null);
    const [preferencesForm] = Form.useForm();

    const { data: profile, isLoading: profileLoading } = useUserProfile();
    const { data: preferences, isLoading: prefsLoading } = useUserPreferences();
    const { data: stats, isLoading: statsLoading } = useUserStats();
    const { data: checkins, isLoading: checkinsLoading } = useUserCheckins();
    const { data: gamification, isLoading: gamificationLoading } = useGamificationProfile();

    const loading = gamificationLoading || profileLoading || prefsLoading || statsLoading;

    useEffect(() => {
        if (!open) {
            setTimeout(() => setView('MAIN'), 300);
        } else if (preferences) {
            // Sync backend data to the central form
            preferencesForm.setFieldsValue(preferences);
        }
    }, [open, preferences, preferencesForm]);

    const updateProfileMutation = useMutation({
        mutationFn: (values) => userApi.updateProfile(values),
        onSuccess: () => {
            queryClient.invalidateQueries(["user", "profile"]);
            message.success("Your profile is all set! ✨");
            setView('MAIN');
        },
        onError: (err) => {
            message.error(err?.friendlyMessage || "Failed to update profile");
        }
    });

    const updatePrefsMutation = useMutation({
        mutationFn: (values) => userApi.updatePreferences(values),
        onSuccess: () => {
            queryClient.invalidateQueries(["user", "preferences"]);
            message.success("Preferences saved! 🌍");
            setView('MAIN');
        },
        onError: (err) => {
            message.error(err?.friendlyMessage || "Failed to update preferences");
        }
    });

    // --- Helpers ---
    const formatLabel = (val) => {
        if (!val) return "";
        if (typeof val !== 'string') return val;
        if (val.length <= 2) return val.toUpperCase();
        const lower = val.toLowerCase().replace(/_/g, " ");
        return lower.charAt(0).toUpperCase() + lower.slice(1);
    };

    const handleOpenPicker = (field) => {
        setPickerField(field);
        setView('PICKER');
    };

    // ================= MAIN VIEW =================
    const MainView = () => (
        <div style={{ background: "#fff", minHeight: "100%" }}>
            <div style={{ padding: "0 24px", position: "sticky", top: 0, zIndex: 10, background: "#fff", paddingBottom: "8px" }}>
                <GrabHandle />
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20, marginTop: 12 }}>
                    <div style={{ fontSize: 22, fontWeight: 900, color: "#1c1c1e" }}>Profile</div>
                    <Button
                        icon={<CloseOutlined style={{ fontSize: 14 }} />}
                        type="text"
                        style={{
                            color: "#6b7280", padding: 0, width: 32, height: 32,
                            borderRadius: "50%", background: "#f3f4f6",
                            display: "flex", alignItems: "center", justifyContent: "center"
                        }}
                        onClick={onClose}
                    />
                </div>
            </div>

            <div style={{ padding: "0 24px 40px" }}>
                <ProfileCharacterCard
                    name={profile?.preferredName || profile?.firstName || profile?.displayName || "—"}
                    role={gamification?.roleText || "—"}
                    level={gamification?.levelText ? parseInt(gamification.levelText.replace(/\D/g, ''), 10) : 1}
                    xp={gamification?.totalXp || 0}
                    progress={gamification?.xpProgressPercent || 0}
                    imageUrl={profile?.profileImageUrl}
                />

                <SectionCard
                    title="Gamification"
                    subtitle="XP, badges, and challenges"
                    icon={<TrophyOutlined />}
                    iconBg="#fb923c"
                    onClick={() => setView('GAMIFICATION')}
                />

                <SectionCard
                    title="Travel Preferences"
                    subtitle="Personalize recommendations"
                    icon={<ControlOutlined />}
                    iconBg="#0ea5e9"
                    onClick={() => setView('EDIT_PREFERENCES')}
                >
                    <div style={{ display: "flex", flexDirection: "column", gap: 14, marginTop: 12 }}>
                        <div style={{ display: "flex" }}>
                            <span style={{ fontSize: 12, color: "#9ca3af", fontWeight: 600, width: 180, flexShrink: 0 }}>Travel style</span>
                            <span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 700 }}>{formatLabel(preferences?.travelStyle) || "—"}</span>
                        </div>

                        <div style={{ display: "flex" }}>
                            <span style={{ fontSize: 12, color: "#9ca3af", fontWeight: 600, width: 180, flexShrink: 0, marginTop: 4 }}>Categories</span>
                            <div style={{ display: "flex", gap: "8px 6px", flexWrap: "wrap", flex: 1 }}>
                                {preferences?.favoriteCategories?.length > 0 ? preferences.favoriteCategories.slice(0, 3).map((cat, i) => (
                                    <div key={i} style={{
                                        padding: "4px 12px", background: "#e0f2fe", color: "#0ea5e9",
                                        borderRadius: 14, fontSize: 12, fontWeight: 700
                                    }}>
                                        {formatLabel(cat)}
                                    </div>
                                )) : (
                                    <span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 700 }}>—</span>
                                )}
                                {(preferences?.favoriteCategories?.length > 3) && <div style={{
                                    padding: "4px 12px", background: "#f3f4f6", color: "#6b7280",
                                    borderRadius: 14, fontSize: 12, fontWeight: 700
                                }}>+{preferences.favoriteCategories.length - 3}</div>}
                            </div>
                        </div>

                        <div style={{ display: "flex" }}>
                            <span style={{ fontSize: 12, color: "#9ca3af", fontWeight: 600, width: 180, flexShrink: 0 }}>Daily budget</span>
                            <span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 700 }}>{preferences?.dailyBudget || "—"} {preferences?.budgetCurrency || 'EUR'}</span>
                        </div>

                        <div style={{ display: "flex", alignItems: "center" }}>
                            <span style={{ fontSize: 12, color: "#9ca3af", fontWeight: 600, width: 180, flexShrink: 0 }}>Dietary</span>
                            {preferences?.dietaryRestrictions?.length > 0 ? (
                                <div style={{
                                    padding: "4px 10px", background: "#fee2e2", color: "#ef4444",
                                    borderRadius: 12, fontSize: 11, fontWeight: 700
                                }}>
                                    {formatLabel(preferences.dietaryRestrictions[0]).charAt(0).toUpperCase() + formatLabel(preferences.dietaryRestrictions[0]).slice(1)}
                                </div>
                            ) : <span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 700 }}>—</span>}
                        </div>

                        <div style={{ display: "flex" }}>
                            <span style={{ fontSize: 12, color: "#9ca3af", fontWeight: 600, width: 180, flexShrink: 0 }}>Language</span>
                            <span style={{ fontSize: 14, color: "#1c1c1e", fontWeight: 700 }}>{(preferences?.preferredLanguage || 'EN').toUpperCase()}</span>
                        </div>
                    </div>
                </SectionCard>

                <SectionCard
                    title="Travel Statistics"
                    subtitle="Your journey so far"
                    icon={<BarChartOutlined />}
                    iconBg="#22c55e"
                >
                    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 12 }}>
                        <div style={{ background: "#f8f9fa", borderRadius: 20, padding: 16 }}>
                            <div style={{ fontSize: 18, fontWeight: 900, color: "#1c1c1e" }}>{stats?.visitedPoisCount || 0}</div>
                            <div style={{ fontSize: 11, color: "#9ca3af", fontWeight: 600, marginTop: 2 }}>Total places visited</div>
                        </div>
                        <div style={{ background: "#f8f9fa", borderRadius: 20, padding: 16 }}>
                            <div style={{ fontSize: 14, fontWeight: 800, color: "#1c1c1e", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{stats?.lastVisitPoiName || "—"}</div>
                            <div style={{ fontSize: 11, color: "#9ca3af", fontWeight: 600, marginTop: 2 }}>{stats?.lastVisitDate ? dayjs(stats.lastVisitDate).format('MMM D, YYYY') : "—"}</div>
                        </div>
                        <div style={{ background: "#f8f9fa", borderRadius: 20, padding: 16 }}>
                            <div style={{ fontSize: 14, fontWeight: 800, color: "#1c1c1e", textTransform: "capitalize" }}>{stats?.favoriteCategory || "—"}</div>
                            <div style={{ fontSize: 11, color: "#9ca3af", fontWeight: 600, marginTop: 2 }}>Favorite category</div>
                        </div>
                        <div style={{ background: "#f8f9fa", borderRadius: 20, padding: 16 }}>
                            <div style={{ fontSize: 18, fontWeight: 900, color: "#1c1c1e" }}>{stats?.distinctCategoriesCount || 0}</div>
                            <div style={{ fontSize: 11, color: "#9ca3af", fontWeight: 600, marginTop: 2 }}>Categories explored</div>
                        </div>
                    </div>
                </SectionCard>

                <SectionCard
                    title="Check-in History"
                    subtitle="Places you've visited"
                    icon={<ClockCircleOutlined />}
                    iconBg="#fb923c"
                >
                    <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 8 }}>
                        {checkins?.length > 0 ? (
                            checkins.slice(0, 3).map((item, idx) => (
                                <CheckinItem key={item.checkInId || idx} name={item.poiName} category={item.category} date={item.checkedInAt} />
                            ))
                        ) : (
                            <div style={{ textAlign: "center", padding: "16px 0", color: "#9ca3af", fontSize: 14, fontWeight: 600 }}>No check-ins yet</div>
                        )}
                    </div>
                </SectionCard>

                <div style={{ marginTop: 24, padding: "0 4px" }}>
                    <div style={{ fontSize: 11, fontWeight: 800, color: "#9ca3af", letterSpacing: "1px", marginBottom: 12, marginLeft: 16 }}>ACCOUNT</div>
                    <div style={{ background: "#fff", borderRadius: 24, padding: "8px 20px", boxShadow: "0 4px 20px rgba(0,0,0,0.03)" }}>
                        <AccountListItem
                            icon={<UserOutlined />}
                            label="Edit Profile"
                            color="#0096FF"
                            bgColor="#e0f2fe"
                            onClick={() => setView('EDIT_PROFILE')}
                        />
                        <AccountListItem
                            icon={<SlidersOutlined />}
                            label="Edit Preferences"
                            color="#22c55e"
                            bgColor="#dcfce7"
                            onClick={() => setView('EDIT_PREFERENCES')}
                        />
                        <AccountListItem
                            icon={<LogoutOutlined />}
                            label="Logout"
                            color="#ff3b30"
                            bgColor="#fee2e2"
                            isLast={true}
                            onClick={() => {
                                import("../firebase").then(({ auth }) => auth.signOut());
                                onClose();
                                navigate("/login");
                            }}
                        />
                    </div>
                </div>
            </div>
        </div>
    );

    // ================= GAMIFICATION VIEW =================
    const GamificationView = () => {
        const levelNum = gamification?.levelText ? parseInt(gamification.levelText.replace(/\D/g, ''), 10) : 1;

        return (
            <div style={{ background: "#f8f9fa", minHeight: "100%" }}>
                <div style={{ padding: "0 24px", position: "sticky", top: 0, zIndex: 10, background: "#f8f9fa", paddingBottom: "8px" }}>
                    <GrabHandle />
                    <div style={{ display: "flex", alignItems: "center", position: "relative", marginBottom: 32, marginTop: 12 }}>
                        <Button
                            icon={<ArrowLeftOutlined />}
                            type="text"
                            style={{ position: "absolute", left: -8, fontSize: 18, color: "#1c1c1e" }}
                            onClick={() => setView('MAIN')}
                        />
                        <div style={{ flex: 1, textAlign: "center", display: "flex", flexDirection: "column", alignItems: "center" }}>
                            <div style={{ fontSize: 13, fontWeight: 800, color: "#9ca3af", textTransform: "uppercase", letterSpacing: "1px", marginBottom: 2 }}>
                                {gamification?.roleText || "Urban Adventurer"}
                            </div>
                            <div style={{ fontSize: 18, fontWeight: 850, color: "#1c1c1e" }}>Level {levelNum}</div>
                        </div>
                        <Button
                            icon={<CloseOutlined style={{ fontSize: 14 }} />}
                            type="text"
                            style={{
                                position: "absolute", right: -8, color: "#6b7280", padding: 0, width: 32, height: 32,
                                borderRadius: "50%", background: "#f3f4f6",
                                display: "flex", alignItems: "center", justifyContent: "center"
                            }}
                            onClick={onClose}
                        />
                    </div>
                </div>

                <div style={{ padding: "0 24px 40px" }}>
                    <div style={{ background: "#fff", borderRadius: 28, padding: "24px 16px 20px", boxShadow: "0 4px 24px rgba(0,0,0,0.04)", textAlign: "center", marginBottom: 24 }}>
                        <div style={{ display: "flex", justifyContent: "center", marginBottom: 20 }}>
                            <Progress
                                type="circle"
                                percent={gamification?.xpProgressPercent || 0}
                                size={140}
                                strokeWidth={8}
                                strokeColor={{ '0%': '#0cebeb', '100%': '#20e3b2' }}
                                format={(percent) => (
                                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                                        <div style={{ fontSize: 28, fontWeight: 900, color: "#1c1c1e", lineHeight: 1 }}>{percent}%</div>
                                        <div style={{ fontSize: 11, fontWeight: 600, color: "#9ca3af", marginTop: 4 }}>to Level {levelNum + 1}</div>
                                        <div style={{ fontSize: 15, fontWeight: 800, color: "#1c1c1e", marginTop: 6 }}>{new Intl.NumberFormat().format(gamification?.totalXp || 0)} XP</div>
                                    </div>
                                )}
                            />
                        </div>

                        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", borderTop: "1px solid #f8f9fa", paddingTop: 16 }}>
                            {gamification?.stats?.slice(0, 3).map((s, idx) => (
                                <div key={s.label} style={{
                                    textAlign: "center",
                                    borderRight: idx < 2 ? "1px solid #f1f3f5" : "none"
                                }}>
                                    <div style={{ fontSize: 28, fontWeight: 900, color: "#1c1c1e" }}>{s.value}</div>
                                    <div style={{ fontSize: 12, fontWeight: 600, color: "#9ca3af", marginTop: 4, textTransform: "capitalize" }}>{s.label}</div>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div style={{ fontSize: 15, fontWeight: 800, color: "#1c1c1e", marginBottom: 16 }}>Achievement Badges</div>

                    <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
                        {gamification?.badges?.map((badge, i) => {
                            const colors = ["#fb923c", "#ef4444", "#0ea5e9", "#22c55e", "#d946ef", "#a855f7"];
                            const bgColor = colors[i % colors.length];

                            return (
                                <div key={badge.id} style={{
                                    background: "#fff", borderRadius: 20, padding: "20px 8px", textAlign: "center",
                                    boxShadow: "0 4px 12px rgba(0,0,0,0.02)",
                                    opacity: badge.earned ? 1 : 0.4
                                }}>
                                    <div style={{
                                        width: 56, height: 56, background: badge.earned ? bgColor : "#f3f4f6",
                                        borderRadius: '50%', display: "flex", alignItems: "center", justifyContent: "center",
                                        margin: "0 auto 12px", fontSize: 24, color: "#fff", boxShadow: badge.earned ? `0 4px 12px ${bgColor}40` : "none"
                                    }}>
                                        {getBadgeIcon(badge.key)}
                                    </div>
                                    <div style={{ fontSize: 12, fontWeight: 800, color: badge.earned ? "#1c1c1e" : "#9ca3af" }}>{badge.title}</div>
                                    {badge.earned && <div style={{ color: "#22c55e", fontSize: 16, fontWeight: 900, marginTop: 4 }}>✓</div>}
                                </div>
                            );
                        })}
                    </div>
                </div>
            </div>
        );
    };

    // ================= EDIT PROFILE VIEW =================
    const EditProfileView = () => {
        const [form] = Form.useForm();

        const GenderSelector = ({ value, onChange }) => {
            const options = [
                { label: "Male", value: "MALE" },
                { label: "Female", value: "FEMALE" },
                { label: "Other", value: "OTHER" },
                { label: "Prefer not to say", value: "PREFER_NOT_TO_SAY" }
            ];
            return (
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
                    {options.map(opt => {
                        const isSelected = value === opt.value;
                        return (
                            <div
                                key={opt.value}
                                onClick={() => onChange(opt.value)}
                                style={{
                                    height: 48, borderRadius: 12, display: "flex", alignItems: "center", padding: "0 16px",
                                    fontSize: 15, fontWeight: 600, cursor: "pointer", transition: "all 0.2s ease",
                                    background: isSelected ? "#0096FF" : "#f3f4f6",
                                    color: isSelected ? "#fff" : "#4b5563"
                                }}
                            >
                                {opt.label}
                            </div>
                        )
                    })}
                </div>
            );
        };

        return (
            <div style={{ background: "#fff", minHeight: "100%", borderRadius: "32px 32px 0 0" }}>
                <div style={{ padding: "0 24px", position: "sticky", top: 0, zIndex: 10, background: "#fff", borderRadius: "32px 32px 0 0", paddingBottom: "8px" }}>
                    <GrabHandle />
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24, marginTop: 12 }}>
                        <Title level={4} style={{ margin: 0, fontWeight: 800, color: "#1c1c1e", fontSize: 17 }}>Edit Profile</Title>
                    </div>
                </div>

                <div style={{ padding: "0 24px 24px" }}>
                    {/* Avatar Area */}
                    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", marginBottom: 24 }}>
                        <div style={{ position: "relative" }}>
                            <Avatar
                                size={86}
                                src={profile?.profileImageUrl}
                                icon={!profile?.profileImageUrl && <UserOutlined />}
                                style={{ border: "2px solid #e5e7eb", background: "#f3f4f6", color: "#9ca3af" }}
                            />
                            <div style={{
                                position: "absolute", bottom: -2, right: -2, width: 32, height: 32,
                                background: "#0096FF", borderRadius: "50%", border: "3px solid #fff",
                                display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer"
                            }}>
                                <CameraFilled style={{ color: "#fff", fontSize: 14 }} />
                            </div>
                        </div>
                        <div style={{ marginTop: 12, fontSize: 13, color: "#9ca3af", fontWeight: 600 }}>Tap camera to change photo</div>
                    </div>

                    {/* Read-only Info Card */}
                    <div style={{ background: "#f8f9fa", borderRadius: 20, padding: "16px", marginBottom: 28 }}>
                        <div style={{ display: "flex", gap: 12, marginBottom: 16 }}>
                            <MailOutlined style={{ color: "#9ca3af", fontSize: 16, marginTop: 8 }} />
                            <div style={{ flex: 1, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                                <div>
                                    <div style={{ fontSize: 10, fontWeight: 800, color: "#9ca3af", letterSpacing: "1px" }}>EMAIL</div>
                                    <div style={{ fontSize: 14, fontWeight: 600, color: "#1c1c1e", marginTop: 2 }}>{profile?.email || ""}</div>
                                </div>
                                <div style={{ background: "#e5e7eb", padding: "4px 8px", borderRadius: 12, fontSize: 10, fontWeight: 700, color: "#6b7280" }}>Read-only</div>
                            </div>
                        </div>

                        <Divider style={{ margin: "0 0 16px 28px", borderColor: "#f3f4f6" }} />

                        <div style={{ display: "flex", gap: 12, marginBottom: 16 }}>
                            <CalendarOutlined style={{ color: "#9ca3af", fontSize: 16, marginTop: 8 }} />
                            <div style={{ flex: 1, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                                <div>
                                    <div style={{ fontSize: 10, fontWeight: 800, color: "#9ca3af", letterSpacing: "1px" }}>ACCOUNT</div>
                                    <div style={{ fontSize: 14, fontWeight: 600, color: "#1c1c1e", marginTop: 2 }}>{profile?.joinDate ? "Member since " + dayjs(profile.joinDate).format('MMMM YYYY') : "—"}</div>
                                </div>
                                <div style={{ background: "#e5e7eb", padding: "4px 8px", borderRadius: 12, fontSize: 10, fontWeight: 700, color: "#6b7280" }}>Read-only</div>
                            </div>
                        </div>

                        <Divider style={{ margin: "0 0 16px 28px", borderColor: "#f3f4f6" }} />

                        <div style={{ display: "flex", gap: 12 }}>
                            <UserOutlined style={{ color: "#0096FF", fontSize: 16, marginTop: 8 }} />
                            <div style={{ flex: 1, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                                <div>
                                    <div style={{ fontSize: 10, fontWeight: 800, color: "#9ca3af", letterSpacing: "1px" }}>DISPLAY NAME</div>
                                    <div style={{ fontSize: 14, fontWeight: 700, color: "#0096FF", marginTop: 2 }}>{profile?.preferredName || profile?.firstName || profile?.displayName || "—"}</div>
                                </div>
                                <div style={{ fontSize: 11, fontWeight: 600, color: "#9ca3af" }}>Auto-computed</div>
                            </div>
                        </div>
                    </div>

                    <div style={{ fontSize: 11, fontWeight: 800, color: "#9ca3af", letterSpacing: "1px", marginBottom: 16 }}>PERSONAL INFO</div>

                    <Form
                        form={form}
                        layout="vertical"
                        initialValues={{
                            firstName: profile?.firstName || "",
                            middleName: profile?.middleName || "",
                            lastName: profile?.lastName || "",
                            preferredName: profile?.preferredName || "",
                            country: profile?.country || "",
                            birthDate: profile?.birthDate ? dayjs(profile.birthDate) : null,
                            gender: profile?.gender || ""
                        }}
                        onFinish={(v) => {
                            // Sanitisation: Convert "" to null to prevent Backend Enum parsing/coercion errors (Fixed: JSON Parse Error 500)
                            const cleanedValues = Object.fromEntries(
                                Object.entries(v).map(([key, val]) => [key, val === "" ? null : val])
                            );
                            updateProfileMutation.mutate({
                                ...cleanedValues,
                                birthDate: v.birthDate ? v.birthDate.format('YYYY-MM-DD') : null
                            });
                        }}
                        requiredMark={false}
                    >
                        <Form.Item
                            label={<span style={{ fontSize: 12, fontWeight: 700, color: "#6b7280" }}>First name <span style={{ color: "#ef4444" }}>*</span></span>}
                            name="firstName"
                            rules={[{ required: true }]}
                            style={{ marginBottom: 20 }}
                        >
                            <Input placeholder="First name" style={{ borderRadius: 16, height: 52, background: "#f3f4f6", border: "none", fontSize: 15, fontWeight: 600, color: "#1c1c1e", boxShadow: "none" }} />
                        </Form.Item>

                        <Form.Item
                            label={<span style={{ fontSize: 12, fontWeight: 700, color: "#6b7280" }}>Middle name <span style={{ color: "#9ca3af", fontWeight: 500 }}>(optional)</span></span>}
                            name="middleName"
                            style={{ marginBottom: 20 }}
                        >
                            <Input placeholder="Middle name" style={{ borderRadius: 16, height: 52, background: "#f3f4f6", border: "none", fontSize: 15, fontWeight: 600, color: "#1c1c1e", boxShadow: "none" }} />
                        </Form.Item>

                        <Form.Item
                            label={<span style={{ fontSize: 12, fontWeight: 700, color: "#6b7280" }}>Last name <span style={{ color: "#ef4444" }}>*</span></span>}
                            name="lastName"
                            rules={[{ required: true }]}
                            style={{ marginBottom: 20 }}
                        >
                            <Input placeholder="Last name" style={{ borderRadius: 16, height: 52, background: "#f3f4f6", border: "none", fontSize: 15, fontWeight: 600, color: "#1c1c1e", boxShadow: "none" }} />
                        </Form.Item>

                        <Form.Item
                            label={<span style={{ fontSize: 12, fontWeight: 700, color: "#6b7280" }}>Preferred name</span>}
                            name="preferredName"
                            style={{ marginBottom: 4 }}
                        >
                            <Input style={{ borderRadius: 16, height: 52, background: "#f3f4f6", border: "none", fontSize: 15, fontWeight: 600, color: "#1c1c1e", boxShadow: "none" }} />
                        </Form.Item>
                        <div style={{ fontSize: 12, fontWeight: 600, color: "#9ca3af", marginBottom: 24, paddingLeft: 4 }}>Overrides your display name across the app</div>

                        <Divider style={{ margin: "24px 0 16px 0", borderColor: "#f3f4f6" }} />

                        <div style={{ fontSize: 11, fontWeight: 800, color: "#9ca3af", letterSpacing: "1px", marginBottom: 16 }}>ADDITIONAL INFO</div>

                        <Form.Item
                            label={<span style={{ fontSize: 12, fontWeight: 700, color: "#6b7280" }}>Country</span>}
                            name="country"
                            style={{ marginBottom: 20 }}
                        >
                            <Input
                                prefix={<GlobalOutlined style={{ color: "#9ca3af", marginRight: 8, fontSize: 16 }} />}
                                suffix={<RightOutlined style={{ color: "#9ca3af", fontSize: 12 }} />}
                                placeholder="United States"
                                style={{ borderRadius: 16, height: 52, background: "#f3f4f6", border: "none", fontSize: 15, fontWeight: 600, color: "#1c1c1e", boxShadow: "none" }}
                            />
                        </Form.Item>

                        <div style={{ marginBottom: 20 }}>
                            <div style={{ fontSize: 12, fontWeight: 700, color: "#6b7280", marginBottom: 8 }}>Date of birth</div>
                            <div style={{ position: "relative", display: "flex", alignItems: "center" }}>
                                <CalendarOutlined style={{ position: "absolute", left: 16, zIndex: 1, color: "#9ca3af", fontSize: 16 }} />
                                <Form.Item name="birthDate" noStyle>
                                    <DatePicker
                                        format="MMMM D, YYYY"
                                        placeholder="Select date"
                                        style={{ width: "100%", borderRadius: 16, height: 52, background: "#f3f4f6", border: "none", fontSize: 15, fontWeight: 600, color: "#1c1c1e", boxShadow: "none", paddingLeft: 42 }}
                                        suffixIcon={<RightOutlined style={{ color: "#9ca3af", fontSize: 12 }} />}
                                    />
                                </Form.Item>
                            </div>
                        </div>

                        <Form.Item
                            label={<span style={{ fontSize: 12, fontWeight: 700, color: "#6b7280" }}>Gender</span>}
                            name="gender"
                            style={{ marginBottom: 0 }}
                        >
                            <GenderSelector />
                        </Form.Item>
                    </Form>
                </div>

                <div style={{ padding: "16px 24px 40px", display: "flex", gap: 12 }}>
                    <Button
                        size="large"
                        onClick={() => setView('MAIN')}
                        style={{ flex: 1, height: 52, borderRadius: 16, fontWeight: 800, color: "#4b5563", background: "#f3f4f6", border: "none" }}
                    >
                        Cancel
                    </Button>
                    <Button
                        type="primary"
                        size="large"
                        loading={updateProfileMutation.isPending}
                        onClick={() => form.submit()}
                        style={{ flex: 1, height: 52, borderRadius: 16, fontWeight: 800, background: "#0096FF", border: "none" }}
                    >
                        Save
                    </Button>
                </div>
            </div>
        );
    };

    // ================= EDIT PREFERENCES VIEW (MOBILE REPLICA) =================
    const EditPreferencesView = ({ onOpenPicker }) => {
        const [showAdvanced, setShowAdvanced] = useState(false);
        const [showMoreTravel, setShowMoreTravel] = useState(false);
        const [showMoreAccommodation, setShowMoreAccommodation] = useState(false);
        const [showMoreTransport, setShowMoreTransport] = useState(false);

        // Sync with central form state
        const watchCategories = Form.useWatch('favoriteCategories', preferencesForm) || [];
        const watchCuisines = Form.useWatch('cuisinePreferences', preferencesForm) || [];
        const watchDietary = Form.useWatch('dietaryRestrictions', preferencesForm) || [];
        const watchAccessibility = Form.useWatch('accessibilityNeeds', preferencesForm) || [];
        const watchLanguage = Form.useWatch('preferredLanguage', preferencesForm);
        const watchTripPace = Form.useWatch('tripPace', preferencesForm);
        const watchActivityLevel = Form.useWatch('activityLevel', preferencesForm);
        const watchAccommodationType = Form.useWatch('accommodationType', preferencesForm);
        const watchTravelStyle = Form.useWatch('travelStyle', preferencesForm);
        const watchSpokenLanguages = Form.useWatch('spokenLanguages', preferencesForm) || [];
        const watchTransportPreference = Form.useWatch('transportPreference', preferencesForm);

        // Options
        const optionTripPace = ["SLOW", "MODERATE", "FAST"];
        const optionAccommodationType = ["HOTEL", "HOSTEL", "APARTMENT", "RESORT", "BOUTIQUE", "ANY"];
        const optionTransportPreference = ["WALKING", "PUBLIC_TRANSPORT", "CAR_RENTAL", "TAXI", "ANY"];
        const optionTravelStyle = ["RELAXATION", "ADVENTURE", "LUXURY", "BACKPACKER", "CULTURAL", "NIGHTLIFE", "FAMILY", "ROMANTIC"];
        const optionLanguages = ["en", "tr", "de", "fr", "es", "it", "pt", "ar", "zh", "ja", "ko", "ru"];

        const accentBlue = "#0096FF";
        const accentOrange = "#F4A261";
        const accentRed = "#FF6B6B";
        const accentPurple = "#9C27B0";
        const accentGreen = "#2ECC71";

        const FieldLabel = ({ text, subtext, color = "#9ca3af" }) => (
            <div style={{ marginBottom: 12, marginTop: 20 }}>
                <div style={{ fontSize: 10, fontWeight: 800, color: color, letterSpacing: "1px" }}>{text.toUpperCase()}</div>
                {subtext && <div style={{ fontSize: 11, color: "#60a5fa", marginTop: 4, display: "flex", alignItems: "center", gap: 4, fontWeight: 600 }}>
                    <ThunderboltOutlined style={{ fontSize: 10 }} /> {subtext}
                </div>}
            </div>
        );

        const MultiSelectRow = ({ label, values, color, onClick }) => {
            const summary = !values || values.length === 0
                ? "None selected" : values.length <= 2
                    ? values.map(v => formatLabel(v)).join(", ")
                    : `${values.slice(0, 2).map(v => formatLabel(v)).join(", ")} +${values.length - 2}`;

            return (
                <div
                    onClick={onClick}
                    style={{
                        background: "#f3f4f6", borderRadius: 16, padding: "14px 16px",
                        display: "flex", alignItems: "center", cursor: "pointer",
                        transition: "all 0.2s ease", border: "none",
                        marginBottom: 10
                    }}
                >
                    <div style={{ flex: 1 }}>
                        <div style={{ fontSize: 11, color: "#9ca3af", fontWeight: 700 }}>{label}</div>
                        <div style={{
                            fontSize: 13, fontWeight: 800, marginTop: 4,
                            color: (!values || values.length === 0) ? "#d1d5db" : color
                        }}>
                            {summary}
                        </div>
                    </div>
                    <RightOutlined style={{ fontSize: 12, color: "#d1d5db" }} />
                </div>
            );
        };

        const ChipSelector = ({ options, value, onChange, color = "#0096FF", isMulti = false, maxVisible = 100, onToggleMore, isExpanded, circle = false }) => {
            const values = isMulti ? (value || []) : [value];
            const visibleOptions = isExpanded ? options : options.slice(0, maxVisible);
            const hasMore = options.length > maxVisible;

            return (
                <div style={{ display: "flex", flexWrap: "wrap", gap: 8, marginBottom: 10 }}>
                    {visibleOptions.map(opt => {
                        const isSelected = isMulti ? values.includes(opt) : value === opt;
                        return (
                            <div
                                key={opt}
                                onClick={() => onChange(opt)}
                                style={{
                                    padding: circle ? "0" : "8px 16px",
                                    width: circle ? 38 : "auto",
                                    height: circle ? 38 : "auto",
                                    borderRadius: circle ? "50%" : 12,
                                    fontSize: 13, fontWeight: 700,
                                    cursor: "pointer", transition: "all 0.2s cubic-bezier(0.4, 0, 0.2, 1)",
                                    background: isSelected ? color : "#f3f4f6",
                                    color: isSelected ? "#fff" : "#6b7280",
                                    display: "flex", alignItems: "center", justifyContent: "center",
                                    border: isSelected ? `1px solid ${color}` : "1px solid transparent",
                                }}
                            >
                                {formatLabel(opt)}
                            </div>
                        );
                    })}
                    {isMulti && values.length > 3 && !circle && (
                        <div style={{ padding: "8px 16px", borderRadius: 12, fontSize: 13, fontWeight: 700, background: "#f3f4f6", color: "#6b7280" }}>
                            +{values.length - 3}
                        </div>
                    )}
                    {hasMore && !isExpanded && (
                        <div
                            onClick={onToggleMore}
                            style={{ padding: "8px 16px", borderRadius: 12, fontSize: 13, fontWeight: 700, background: "#f3f4f6", color: color, cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}
                        >
                            More... <DownOutlined style={{ fontSize: 10 }} />
                        </div>
                    )}
                    {hasMore && isExpanded && (
                        <div
                            onClick={onToggleMore}
                            style={{ padding: "8px 16px", borderRadius: 12, fontSize: 13, fontWeight: 700, background: "#f3f4f6", color: color, cursor: "pointer", display: "flex", alignItems: "center", gap: 4 }}
                        >
                            Less <UpOutlined style={{ fontSize: 10 }} />
                        </div>
                    )}
                </div>
            );
        };

        const SegmentedControl = ({ options, value, onChange }) => (
            <div style={{
                display: "flex", background: "#f3f4f6", borderRadius: 14,
                padding: 4, gap: 4, marginBottom: 4
            }}>
                {options.map(opt => {
                    const isSelected = value === opt;
                    return (
                        <div
                            key={opt}
                            onClick={() => onChange(opt)}
                            style={{
                                flex: 1, textAlign: "center", padding: "10px 0",
                                borderRadius: 11, cursor: "pointer", transition: "all 0.2s ease",
                                background: isSelected ? "#0096FF" : "transparent",
                                color: isSelected ? "#fff" : "#6b7280",
                                fontWeight: 700, fontSize: 13,
                                boxShadow: isSelected ? "0 2px 8px rgba(0,0,0,0.1)" : "none"
                            }}
                        >
                            {formatLabel(opt)}
                        </div>
                    );
                })}
            </div>
        );

        return (
            <div style={{ background: "#fff", minHeight: "100%" }}>
                <div style={{ padding: "0 24px", display: "flex", flexDirection: "column", alignItems: "center", position: "sticky", top: 0, zIndex: 10, background: "#fff", paddingBottom: "8px" }}>
                    <GrabHandle />
                    <div style={{ position: "relative", width: "100%", textAlign: "center", marginBottom: 24, marginTop: 12 }}>
                        <Button
                            icon={<ArrowLeftOutlined />}
                            type="text"
                            style={{ position: "absolute", left: -16, top: 0, fontSize: 18, color: "#9ca3af" }}
                            onClick={() => setView('MAIN')}
                        />
                        <Title level={4} style={{ margin: 0, fontWeight: 850, color: "#1c1c1e" }}>Preferences</Title>
                        <Button
                            icon={<CloseOutlined style={{ fontSize: 14 }} />}
                            type="text"
                            style={{
                                position: "absolute", right: -16, top: 0, color: "#6b7280", padding: 0, width: 32, height: 32,
                                borderRadius: "50%", background: "#f3f4f6",
                                display: "flex", alignItems: "center", justifyContent: "center"
                            }}
                            onClick={onClose}
                        />
                    </div>
                </div>

                <div style={{ padding: "0 20px 40px" }}>
                    <Form form={preferencesForm} layout="vertical" onFinish={(v) => updatePrefsMutation.mutate(v)}>
                        <Form.Item name="favoriteCategories" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="cuisinePreferences" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="dietaryRestrictions" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="accessibilityNeeds" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="spokenLanguages" noStyle><input type="hidden" /></Form.Item>

                        <Form.Item name="travelStyle" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="tripPace" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="accommodationType" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="transportPreference" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="preferredLanguage" noStyle><input type="hidden" /></Form.Item>
                        <Form.Item name="activityLevel" noStyle><input type="hidden" /></Form.Item>

                        <FieldLabel text="Basics" />

                        <FieldLabel text="Travel Style" color="#9ca3af" />
                        <ChipSelector
                            options={optionTravelStyle}
                            value={watchTravelStyle}
                            onChange={v => preferencesForm.setFieldsValue({ travelStyle: v })}
                            color={accentBlue}
                            maxVisible={5}
                            isExpanded={showMoreTravel}
                            onToggleMore={() => setShowMoreTravel(!showMoreTravel)}
                        />

                        <FieldLabel text="Favorite Categories" color="#9ca3af" />
                        <ChipSelector options={watchCategories} value={watchCategories} isMulti={true} color={accentBlue} maxVisible={3} />
                        <MultiSelectRow label="Select categories" values={watchCategories} color={accentBlue} onClick={() => handleOpenPicker('categories')} />

                        <FieldLabel text="Daily Budget" />
                        <Row gutter={8}>
                            <Col span={17}>
                                <Form.Item name="dailyBudget" noStyle>
                                    <InputNumber
                                        placeholder="150"
                                        style={{ width: '100%', borderRadius: 16, height: 52, display: 'flex', alignItems: 'center', background: "#f3f4f6", border: "none", fontSize: 16, fontWeight: 700 }}
                                    />
                                </Form.Item>
                            </Col>
                            <Col span={7}>
                                <Form.Item name="budgetCurrency" noStyle>
                                    <Select
                                        variant="borderless"
                                        style={{ width: '100%', height: 52, background: "#f3f4f6", borderRadius: 16, fontSize: 14, fontWeight: 700 }}
                                        options={["EUR", "USD", "GBP", "TRY"].map(c => ({ label: c, value: c }))}
                                    />
                                </Form.Item>
                            </Col>
                        </Row>

                        <div onClick={() => setShowAdvanced(!showAdvanced)} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "16px 0", cursor: "pointer" }}>
                            <div style={{ fontSize: 11, fontWeight: 800, color: "#9ca3af", letterSpacing: "1px" }}>ADVANCED PREFERENCES</div>
                            <div style={{ display: "flex", alignItems: "center", gap: 6, color: "#9ca3af", fontSize: 12, fontWeight: 700 }}>
                                {showAdvanced ? "Hide" : "Show"} {showAdvanced ? <UpOutlined style={{ fontSize: 10 }} /> : <DownOutlined style={{ fontSize: 10 }} />}
                            </div>
                        </div>

                        {showAdvanced && (
                            <div style={{ animation: "fadeIn 0.3s ease" }}>
                                <FieldLabel text="Activity Level" />
                                <Form.Item name="activityLevel" noStyle>
                                    <SegmentedControl options={["LOW", "MODERATE", "HIGH"]} value={watchActivityLevel} onChange={v => preferencesForm.setFieldsValue({ activityLevel: v })} />
                                </Form.Item>

                                <FieldLabel text="Cuisine Preferences" />
                                <ChipSelector options={watchCuisines} value={watchCuisines} isMulti={true} color={accentOrange} maxVisible={3} />
                                <MultiSelectRow label="Select cuisines" values={watchCuisines} color={accentOrange} onClick={() => handleOpenPicker('cuisines')} />

                                <FieldLabel text="Dietary Restrictions & Allergens" subtext="Used by AI to filter recommendations" />
                                <ChipSelector options={watchDietary} value={watchDietary} isMulti={true} color={accentRed} maxVisible={3} />
                                <MultiSelectRow label="Select dietary restrictions" values={watchDietary} color={accentRed} onClick={() => handleOpenPicker('dietary')} />

                                <FieldLabel text="Accessibility Needs" />
                                <MultiSelectRow label="Select accessibility needs" values={watchAccessibility} color={accentPurple} onClick={() => handleOpenPicker('accessibility')} />

                                <FieldLabel text="Trip Pace" />
                                <Form.Item name="tripPace" noStyle>
                                    <SegmentedControl options={optionTripPace} value={watchTripPace} onChange={v => preferencesForm.setFieldsValue({ tripPace: v })} />
                                </Form.Item>

                                <FieldLabel text="Accommodation Type" />
                                <ChipSelector
                                    options={optionAccommodationType}
                                    value={watchAccommodationType}
                                    onChange={v => preferencesForm.setFieldsValue({ accommodationType: v })}
                                    color={accentBlue}
                                    maxVisible={3}
                                    isExpanded={showMoreAccommodation}
                                    onToggleMore={() => setShowMoreAccommodation(!showMoreAccommodation)}
                                />

                                <FieldLabel text="Transport preference" />
                                <ChipSelector
                                    options={optionTransportPreference}
                                    value={watchTransportPreference}
                                    onChange={v => preferencesForm.setFieldsValue({ transportPreference: v })}
                                    color={accentBlue}
                                    maxVisible={3}
                                    isExpanded={showMoreTransport}
                                    onToggleMore={() => setShowMoreTransport(!showMoreTransport)}
                                />

                                <FieldLabel text="Preferred Language" />
                                <ChipSelector options={optionLanguages} value={watchLanguage} onChange={v => preferencesForm.setFieldsValue({ preferredLanguage: v })} color={accentBlue} circle={true} maxVisible={7} />

                                <FieldLabel text="Spoken Languages" />
                                <ChipSelector options={watchSpokenLanguages} value={watchSpokenLanguages} isMulti={true} color={accentGreen} maxVisible={3} />
                                <MultiSelectRow label="Select spoken languages" values={watchSpokenLanguages} color={accentGreen} onClick={() => handleOpenPicker('spokenLanguages')} />
                            </div>
                        )}
                    </Form>
                </div>

                <div style={{ padding: 20, display: "flex", gap: 12 }}>
                    <Button block size="large" onClick={() => setView('MAIN')} style={{ height: 52, borderRadius: 16, fontWeight: 800, color: "#4b5563" }}>Cancel</Button>
                    <Button type="primary" block size="large" onClick={() => preferencesForm.submit()} style={{ height: 52, borderRadius: 16, fontWeight: 800, background: "#0096FF" }}>Save</Button>
                </div>
            </div>
        );
    };

    const FullScreenPickerView = ({ title, options, fieldName, form, onBack, themeColor = "#0096FF" }) => {
        const [search, setSearch] = useState("");
        const [selectedValues, setSelectedValues] = useState(() => form.getFieldValue(fieldName) || []);

        const filteredOptions = options.filter(opt => opt.toLowerCase().includes(search.toLowerCase()));

        const toggleSelection = (val) => {
            const newValues = selectedValues.includes(val)
                ? selectedValues.filter(v => v !== val)
                : [...selectedValues, val];
            setSelectedValues(newValues);
        };

        const handleDone = () => {
            form.setFieldsValue({ [fieldName]: selectedValues });
            onBack();
        };

        const CustomCheckbox = ({ checked }) => (
            <div style={{
                width: 22, height: 22, borderRadius: 6,
                border: checked ? `none` : "2px solid #e5e7eb",
                background: checked ? themeColor : "transparent",
                display: "flex", alignItems: "center", justifyContent: "center",
                transition: "all 0.2s ease",
                flexShrink: 0
            }}>
                {checked && (
                    <svg width="12" height="12" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M13.3333 4L5.99996 11.3333L2.66663 8" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                )}
            </div>
        );

        return (
            <div style={{ background: "#fff", minHeight: "100%", borderRadius: "32px 32px 0 0" }}>
                <div style={{ padding: "0 24px", position: "sticky", top: 0, zIndex: 10, background: "#fff", borderRadius: "32px 32px 0 0" }}>
                    <GrabHandle />
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 20, marginTop: 12 }}>
                        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                            <Button
                                icon={<ArrowLeftOutlined style={{ fontSize: 16 }} />}
                                type="text"
                                style={{
                                    color: "#6b7280", padding: 0, width: 36, height: 36,
                                    borderRadius: "50%", background: "#f3f4f6",
                                    display: "flex", alignItems: "center", justifyContent: "center"
                                }}
                                onClick={handleDone}
                            />
                            <Title level={4} style={{ margin: 0, fontWeight: 800, color: "#1c1c1e", fontSize: 18 }}>{title}</Title>
                        </div>
                        <div style={{ fontSize: 13, color: "#9ca3af", fontWeight: 600 }}>{selectedValues.length} selected</div>
                    </div>
                </div>

                <div style={{ padding: "0 24px 16px", position: "sticky", top: "72px", zIndex: 10, background: "#fff", borderBottom: "1px solid #f3f4f6" }}>
                    <Input prefix={<SearchOutlined style={{ color: "#9ca3af" }} />} placeholder="Search..." value={search} onChange={e => setSearch(e.target.value)} style={{ height: 48, borderRadius: 12, border: "none", background: "#f3f4f6", fontSize: 15, fontWeight: 500 }} />
                </div>

                <div style={{ padding: "0 24px 24px" }}>
                    {filteredOptions.map(opt => {
                        const isSelected = selectedValues.includes(opt);
                        return (
                            <div
                                key={opt}
                                onClick={() => toggleSelection(opt)}
                                style={{
                                    padding: "16px 0",
                                    borderBottom: "1px solid #f8f9fa",
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 16,
                                    cursor: "pointer"
                                }}
                            >
                                <CustomCheckbox checked={isSelected} />
                                <span style={{
                                    fontSize: 15,
                                    fontWeight: 600,
                                    color: "#1c1c1e",
                                    transition: "all 0.2s ease"
                                }}>
                                    {formatLabel(opt)}
                                </span>
                            </div>
                        );
                    })}
                </div>

                <div style={{ padding: "24px 24px 40px" }}>
                    <Button
                        type="primary"
                        block
                        size="large"
                        onClick={handleDone}
                        style={{
                            height: 52, borderRadius: 16, fontWeight: 800, fontSize: 15,
                            background: themeColor, border: "none"
                        }}
                    >
                        Done ({selectedValues.length} selected)
                    </Button>
                </div>
            </div>
        );
    };

    return (
        <Modal open={open} onCancel={onClose} footer={null} width={480} centered closeIcon={false} styles={{ body: { padding: "0", background: "#f8f9fa", maxHeight: "88vh", overflowY: "auto", overflowX: "hidden" } }} style={{ borderRadius: "32px", overflow: "hidden" }}>
            {view === 'MAIN' && <MainView />}
            {view === 'GAMIFICATION' && <GamificationView />}
            {view === 'EDIT_PROFILE' && <EditProfileView />}
            {view === 'EDIT_PREFERENCES' && <EditPreferencesView onOpenPicker={handleOpenPicker} />}
            {view === 'PICKER' && (
                <FullScreenPickerView
                    title={
                        pickerField === 'categories' ? "Favorite Categories" :
                            pickerField === 'cuisines' ? "Cuisine Preferences" :
                                pickerField === 'dietary' ? "Dietary Restrictions" :
                                    pickerField === 'spokenLanguages' ? "Spoken Languages" :
                                        "Accessibility Needs"
                    }
                    fieldName={
                        pickerField === 'categories' ? 'favoriteCategories' :
                            pickerField === 'cuisines' ? 'cuisinePreferences' :
                                pickerField === 'dietary' ? 'dietaryRestrictions' :
                                    pickerField === 'spokenLanguages' ? 'spokenLanguages' :
                                        'accessibilityNeeds'
                    }
                    themeColor={
                        pickerField === 'categories' ? "#0096FF" :
                            pickerField === 'cuisines' ? "#ffa26b" :
                                pickerField === 'dietary' ? "#ff4d4f" :
                                    pickerField === 'spokenLanguages' ? "#2ECC71" :
                                        "#7c3aed"
                    }
                    options={
                        pickerField === 'categories' ? ["museum", "park", "cafe", "restaurant", "beach", "market", "gallery", "temple", "nature", "bar", "shopping", "nightclub", "landmark"] :
                            pickerField === 'cuisines' ? ["turkish", "italian", "french", "japanese", "mexican", "indian", "greek", "thai", "chinese", "american"] :
                                pickerField === 'dietary' ? ["gluten-free", "lactose-free", "vegan", "vegetarian", "halal", "kosher", "sugar-free", "peanut-free"] :
                                    pickerField === 'spokenLanguages' ? ["en", "tr", "de", "fr", "es", "it", "pt", "ar", "zh", "ja", "ko", "ru"] :
                                        ["wheelchair", "elevator", "braille", "audio-guide", "low-sensory"]
                    }
                    form={preferencesForm}
                    onBack={() => setView('EDIT_PREFERENCES')}
                />
            )}
        </Modal>
    );
};

export default ProfileModal;

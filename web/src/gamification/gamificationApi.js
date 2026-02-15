import http from "../api/http";

export const fetchMyGamification = async () => {
  const { data } = await http.get("/gamification/profile");
  return data;
};

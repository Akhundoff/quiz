import React, { createContext, useContext, useState, useEffect } from 'react';
import { authAPI } from '../services/api';

const AuthContext = createContext();

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(localStorage.getItem('adminToken'));
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (token) {
            // Verify token validity
            authAPI.defaults.headers.common['Authorization'] = `Bearer ${token}`;
            // You can add token verification here
        }
        setLoading(false);
    }, [token]);

    const login = async (username, password) => {
        try {
            const response = await authAPI.post('/admin/login', { username, password });
            const { access_token, user: userData } = response.data;

            setToken(access_token);
            setUser(userData);
            localStorage.setItem('adminToken', access_token);
            authAPI.defaults.headers.common['Authorization'] = `Bearer ${access_token}`;

            return { success: true };
        } catch (error) {
            return {
                success: false,
                message: error.response?.data?.message || 'Login failed'
            };
        }
    };

    const logout = () => {
        setToken(null);
        setUser(null);
        localStorage.removeItem('adminToken');
        delete authAPI.defaults.headers.common['Authorization'];
    };

    const value = {
        user,
        token,
        login,
        logout,
        loading,
        isAuthenticated: !!token,
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};
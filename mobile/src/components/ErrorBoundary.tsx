import React from 'react';
import { View, Text, Button } from 'react-native';

export class ErrorBoundary extends React.Component {
    state = { hasError: false, error: null };

    static getDerivedStateFromError(error) {
        return { hasError: true, error };
    }

    componentDidCatch(error, errorInfo) {
        console.error("Uncaught error:", error, errorInfo);
    }

    render() {
        if (this.state.hasError) {
            return (
                <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20 }}>
                    <Text style={{ fontSize: 20, fontWeight: 'bold', marginBottom: 10 }}>Something went wrong</Text>
                    <Text style={{ marginBottom: 20, color: 'red' }}>{this.state.error?.toString()}</Text>
                    <Button title="Try Again" onPress={() => this.setState({ hasError: false })} />
                </View>
            );
        }

        return this.props.children;
    }
}

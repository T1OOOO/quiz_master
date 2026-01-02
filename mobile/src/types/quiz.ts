export interface Category {
    id: string;
    title: string;
}

export interface Question {
    id: string;
    text: string;
    options: string[];
    explanation?: string;
    image_url?: string;
    difficulty?: number;
    _optionMapping?: { opt: string; originalIdx: number }[];
}

export interface Quiz {
    id: string;
    title: string;
    description: string;
    category?: Category | string;
    questions: Question[];
    questions_count?: number;
}

export interface Feedback {
    correct: boolean;
    correct_answer: number;
    explanation?: string;
    correct_text?: string;
}

export interface QuizStats {
    correct: number;
    incorrect: number;
    answered: number;
    total: number;
}

import { Question } from '../types/quiz';

/**
 * Fisher-Yates Shuffle
 */
export function shuffleArray<T>(array: T[]): T[] {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
}

/**
 * Process a single question to shuffle its options and track mapping
 */
export function processSingleQuestion(q: Question): Question {
    // Create an array of indices [0, 1, 2, 3]
    const indices = q.options.map((_, i) => i);
    // Shuffle the indices
    const shuffledIndices = shuffleArray(indices);
    
    // Map options to new positions
    const shuffledOptions = shuffledIndices.map(i => q.options[i]);
    
    // Store mapping to find original index later
    const mapping = shuffledIndices.map((originalIdx, currentIdx) => ({
        opt: q.options[originalIdx],
        originalIdx
    }));

    return {
        ...q,
        options: shuffledOptions,
        _optionMapping: mapping,
        _fullyLoaded: true
    };
}

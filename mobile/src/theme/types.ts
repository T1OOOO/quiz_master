export interface ThemeStyles {
    page?: string;
    overlay?: string;
    heading?: string;
    subtext?: string;
    text?: string;
    sidebar?: string;
    sidebarHeader?: string;
    sidebarScrollbar?: string;
    item?: string;
    itemActive?: string;
    itemCorrect?: string;
    itemIncorrect?: string;
    itemUnanswered?: string;
    itemIcon?: string;
    card?: string;
    cardWrapper?: string;
    cardImage?: string;
    cardHeader?: string;
    cardTitle?: string;
    progressBar?: string;
    progressFill?: string;
    pill?: string;
    pillActive?: string;
    pillCorrect?: string;
    pillIncorrect?: string;
    pillNeutral?: string;
    primaryButton?: string;
    option?: string;
    optionSelected?: string;
    optionCorrect?: string;
    optionIncorrect?: string;
    optionIcon?: string;
    explanation?: string;
    btnShuffle?: string;
    btnReset?: string;
    btnSecondary?: string;
    folderCard?: string;
    folderIcon?: string;
    folderText?: string;
    quizCard?: string;
    [key: string]: string | undefined;
}

export interface ThemeConfig {
    name: string;
    background: any;
    confetti: string[];
    styles: ThemeStyles;
}

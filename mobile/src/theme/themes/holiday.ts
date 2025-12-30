import { ThemeConfig } from '../types';
import homeAloneBg from '../../../assets/home-alone-bg.jpg';

export const holidayTheme: ThemeConfig = {
    name: 'Праздник',
    background: homeAloneBg,
    confetti: ['#b91c1c', '#166534', '#eab308'],
    styles: {
        // General
        page: "bg-cover bg-center bg-no-repeat transition-all duration-700",
        overlay: "bg-amber-950/20 backdrop-blur-[0.5px]", // Rich warm overlay

        // Text - Sophisticated Serif
        heading: "text-stone-900 font-serif tracking-tight",
        subtext: "text-stone-500",
        text: "text-stone-800",

        // Sidebar - Festive Gift List
        sidebar: "bg-white border-r border-red-100",
        sidebarHeader: "px-5 pt-14 pb-4 border-b border-red-100 bg-red-50/50",
        sidebarScrollbar: "",

        // Sidebar Items - Festive Ribbons/Cards
        item: "mx-3 mb-3 p-4 rounded-xl shadow-sm border-l-4 border-l-red-300 bg-red-500 transition-all",
        itemActive: "bg-amber-300 border-l-amber-500 shadow-md ring-2 ring-amber-100",
        itemCorrect: "bg-emerald-500 border-l-emerald-700 opacity-90",
        itemIncorrect: "bg-rose-500 border-l-rose-700 opacity-90",
        itemUnanswered: "bg-red-500",
        itemIcon: "w-8 h-8 rounded-full items-center justify-center bg-white/20",

        // Question Card - Luxury Stationery
        card: "bg-stone-50 text-stone-900 shadow-2xl rounded-[2.5rem] border border-stone-200/60 overflow-hidden",
        cardWrapper: "perspective-2000",
        cardImage: "opacity-80 grayscale-[0.1]",
        cardHeader: "p-8 md:p-10 border-b border-stone-200/40 bg-stone-100/20",
        cardTitle: "text-stone-900 font-serif italic text-3xl tracking-tight leading-relaxed",

        // Progress
        progressBar: "bg-stone-200/40 h-2 rounded-full overflow-hidden",
        progressFill: "bg-red-800 shadow-[0_0_10px_rgba(153,27,27,0.4)]",

        // Pills
        pill: "bg-white border-stone-200 text-stone-600 shadow-sm",
        pillActive: "text-red-900 font-bold",
        
        // Buttons
        primaryButton: "w-full mt-10 py-6 rounded-2xl bg-red-900 text-stone-50 font-serif font-bold text-xl shadow-2xl hover:bg-black active:scale-[0.97] transition-all flex items-center justify-center gap-3 border-t border-red-500/20",

        // Options - Modern Clean
        option: "bg-white border border-stone-200/60 rounded-2xl p-6 mb-5 shadow-sm hover:shadow-md hover:border-stone-300 transition-all",
        optionSelected: "bg-amber-50/30 border-amber-400 shadow-md ring-1 ring-amber-200/20",
        optionCorrect: "bg-emerald-50/60 border-emerald-500 shadow-inner",
        optionIncorrect: "bg-rose-50/60 border-rose-400 opacity-90",
        optionIcon: "w-10 h-10 bg-stone-50 rounded-xl items-center justify-center border border-stone-200 font-serif text-stone-700",

        // Explanation - Classy Note
        explanation: "bg-amber-50/30 border border-amber-200/40 text-stone-800 font-serif italic p-8 rounded-2xl leading-relaxed shadow-sm",

        // Buttons
        btnShuffle: "bg-stone-100 text-stone-700 border-stone-200 hover:bg-stone-200",
        btnReset: "bg-stone-100 text-stone-700 border-stone-200 hover:bg-stone-200",
        btnSecondary: "bg-stone-100 text-stone-700 border-stone-200",

        // Folder/Quiz Cards
        folderCard: "bg-white border border-stone-200 hover:bg-stone-50 shadow-md rounded-2xl",
        folderIcon: "bg-red-900/10 text-red-900",
        folderText: "text-stone-900 font-serif font-bold text-lg",
        quizCard: "bg-white/70 backdrop-blur-md border border-stone-200/50 hover:bg-white/90 shadow-xl rounded-[2rem]",
    }
};

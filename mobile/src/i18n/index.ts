import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { getLocales } from 'expo-localization';
import 'intl-pluralrules';

import ru from './locales/ru.json';
import en from './locales/en.json';

const resources = {
  en: { translation: en },
  ru: { translation: ru },
};

i18n
  .use(initReactI18next)
  .init({
    resources,
    lng: getLocales()[0].languageCode ?? 'ru',
    fallbackLng: 'ru',
    interpolation: {
      escapeValue: false, // react already safes from xss
    },
    cleanCode: true,
  });

export default i18n;

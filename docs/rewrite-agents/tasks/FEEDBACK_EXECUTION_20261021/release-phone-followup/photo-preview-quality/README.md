# Качество миниатюр достопримечательностей

Пакет пересоздаёт ровно 46 существующих `thumbnail_asset` для раздела
`landmarks` из их парных `image_asset`. Скрипт применяет EXIF-ориентацию,
вписывает изображение в квадрат 512×512 без увеличения относительно оригинала
и сохраняет WebP с quality 76 / method 6. Исходные фотографии и каталог не
изменяются, внешние загрузки и новые ассеты не используются.

Запуск из корня репозитория:

```powershell
python docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/release-phone-followup/photo-preview-quality/regenerate_landmark_thumbnails.py `
  --manifest docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/release-phone-followup/photo-preview-quality/manifest.json
```

Манифест содержит SHA-256, размеры и байты каждого оригинала, старой и новой
миниатюры, а также агрегаты и версии инструментов.

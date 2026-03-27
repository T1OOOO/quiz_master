# Scoop Manifest для Quiz Master

Этот манифест позволяет установить Quiz Master через Scoop (пакетный менеджер для Windows).

## Установка Scoop

Если у вас еще не установлен Scoop:

```powershell
# Установка Scoop
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

## Установка зависимостей через Scoop

```powershell
# Go для бэкенда
scoop install go

# Flutter для мобильного приложения
scoop install flutter

# Node.js для React Native (опционально)
scoop install nodejs

# Git (если еще не установлен)
scoop install git
```

## Установка Quiz Master

```powershell
# Добавить bucket (если используете свой bucket)
scoop bucket add quiz-master https://github.com/yourusername/quiz-master-scoop

# Установить приложение
scoop install quiz-master
```

## Разработка

Для разработки установите все зависимости:

```powershell
# Все зависимости для разработки
scoop install go flutter nodejs git
```

## Обновление

```powershell
scoop update quiz-master
```

## Удаление

```powershell
scoop uninstall quiz-master
```

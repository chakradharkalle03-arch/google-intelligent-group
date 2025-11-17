# 啟用 Places API 指南

## 🔴 當前問題

測試結果顯示：
- ✅ **Geocoding API**: 正常工作
- ❌ **Places API**: 需要啟用舊版 API 或遷移到新版本

錯誤訊息：`You're calling a legacy API, which is not enabled for your project`

## ✅ 解決方案

### 方法 1：啟用舊版 Places API（快速修復）

1. 前往 Google Cloud Console API Library：
   https://console.cloud.google.com/apis/library

2. 搜尋並啟用以下 API：
   - **Places API** (舊版)
     - 直接連結：https://console.cloud.google.com/apis/library/places-backend.googleapis.com
     - 點擊「啟用」按鈕

3. 等待幾分鐘讓 API 生效

4. 重新測試：
   ```powershell
   .\test_google_maps_api.ps1
   ```

### 方法 2：遷移到 Places API (New)（推薦，長期方案）

新的 Places API 提供更多功能和更好的效能，但需要修改程式碼。

**啟用新 API：**
1. 前往：https://console.cloud.google.com/apis/library
2. 搜尋並啟用：**Places API (New)**
   - 直接連結：https://console.cloud.google.com/apis/library/places-backend.googleapis.com
3. 點擊「啟用」

**注意**：遷移到新 API 需要修改程式碼，因為端點和請求格式不同。

## 📋 確認步驟

啟用 API 後，請確認：

1. ✅ **Places API** 已啟用
2. ✅ **Geocoding API** 已啟用（已確認正常）
3. ✅ **API 金鑰限制**設定正確：
   - 無 HTTP referrer 限制，或
   - 使用 IP 位址限制（包含 `127.0.0.1`）
4. ✅ **計費帳戶**已啟用

## 🧪 測試

執行測試腳本確認所有 API 正常：

```powershell
.\test_google_maps_api.ps1
```

如果看到兩個 ✅，表示所有 API 都已正常運作。

## 🔄 重新啟動後端

API 啟用後，重新啟動後端伺服器：

```powershell
.\run_web.ps1
```

## 📝 注意事項

- API 啟用可能需要幾分鐘時間生效
- 確保您的 Google Cloud 專案有啟用計費（即使有免費額度）
- 舊版 Places API 將在未來被淘汰，建議長期規劃遷移到新版本


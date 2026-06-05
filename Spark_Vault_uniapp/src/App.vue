<script>
export default {
  onLaunch() {},
  onShow() {},
  onHide() {}
}
</script>

<style>
page {
  background: #fbf9f6;
  color: #1c1b1f;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}

.iv-page {
  min-height: 100vh;
  padding: 32rpx;
  box-sizing: border-box;
  background: #fbf9f6;
}

.iv-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24rpx;
  margin: 8rpx 0 32rpx;
}

.iv-brand {
  display: block;
  font-size: 52rpx;
  line-height: 1.1;
  font-weight: 600;
  color: #1c1b1f;
}

.iv-kicker {
  display: block;
  margin-top: 6rpx;
  font-size: 22rpx;
  line-height: 1.2;
  font-weight: 800;
  letter-spacing: 3rpx;
  color: #49454f;
}

.iv-title {
  display: block;
  font-size: 44rpx;
  line-height: 1.18;
  font-weight: 800;
  color: #004a77;
}

.iv-subtitle {
  display: block;
  margin-top: 8rpx;
  font-size: 24rpx;
  line-height: 1.55;
  color: #49454f;
}

.iv-section-title {
  display: block;
  margin: 32rpx 0 16rpx;
  font-size: 30rpx;
  font-weight: 700;
  color: #1c1b1f;
}

.iv-card {
  background: #ffffff;
  border: 1rpx solid #e6e1e5;
  border-radius: 32rpx;
  box-sizing: border-box;
}

.iv-card-padded {
  padding: 28rpx;
}

.iv-soft-card {
  background: #d7e3ff;
  border-radius: 40rpx;
  padding: 36rpx;
  box-sizing: border-box;
}

.iv-icon-circle {
  width: 80rpx;
  height: 80rpx;
  border-radius: 999rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #eaddff;
  color: #6750a4;
  font-size: 32rpx;
  font-weight: 800;
}

.iv-muted-circle {
  background: #e6e1e5;
  color: #49454f;
  border: 1rpx solid #cac4d0;
}

.iv-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16rpx;
}

.iv-stat {
  min-height: 164rpx;
  padding: 28rpx;
}

.iv-stat-icon {
  display: block;
  font-size: 28rpx;
  color: #004a77;
}

.iv-label {
  display: block;
  margin-top: 14rpx;
  font-size: 22rpx;
  line-height: 1.25;
  font-weight: 800;
  color: #49454f;
}

.iv-value {
  display: block;
  margin-top: 6rpx;
  font-size: 34rpx;
  line-height: 1.15;
  font-weight: 700;
  color: #004a77;
  word-break: break-word;
}

.iv-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.iv-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
}

.iv-button,
.iv-outline-button {
  min-height: 88rpx;
  border-radius: 24rpx;
  font-size: 25rpx;
  font-weight: 700;
  line-height: 88rpx;
}

.iv-button {
  background: #004a77;
  color: #ffffff;
}

.iv-outline-button {
  background: #ffffff;
  color: #004a77;
  border: 1rpx solid #004a77;
}

.iv-input,
.iv-textarea,
.iv-picker {
  width: 100%;
  background: #ffffff;
  border: 1rpx solid #e6e1e5;
  border-radius: 18rpx;
  padding: 22rpx 24rpx;
  box-sizing: border-box;
  font-size: 26rpx;
  color: #1c1b1f;
}

.iv-textarea {
  min-height: 220rpx;
  line-height: 1.55;
}

.iv-chip-row {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
}

.iv-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 56rpx;
  padding: 0 22rpx;
  border-radius: 999rpx;
  background: #f3edf7;
  color: #6750a4;
  font-size: 22rpx;
  font-weight: 700;
}

.iv-chip.active {
  background: #004a77;
  color: #ffffff;
}

.iv-badge {
  display: inline-flex;
  padding: 8rpx 18rpx;
  border-radius: 12rpx;
  background: #f3edf7;
  color: #6750a4;
  font-size: 20rpx;
  line-height: 1.2;
  font-weight: 800;
  letter-spacing: 1rpx;
}

.iv-badge.web {
  background: #e8def8;
  color: #1d192b;
}

.iv-badge.other {
  background: #d7e3ff;
  color: #001d35;
}

.iv-body {
  display: block;
  font-size: 26rpx;
  line-height: 1.58;
  color: #1c1b1f;
}

.iv-caption {
  display: block;
  font-size: 22rpx;
  line-height: 1.45;
  color: #49454f;
}

.iv-reflection {
  margin-top: 20rpx;
  padding: 20rpx;
  border-radius: 20rpx;
  background: rgba(243, 237, 247, 0.65);
}
</style>

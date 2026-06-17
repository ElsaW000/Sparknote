<script>
export default {
  onLaunch() {},
  onShow() {},
  onHide() {}
}
</script>

<style>
page {
  background: #f2f0e9;
  color: #1a1a1a;
  font-family: "Times New Roman", "PingFang SC", "Microsoft YaHei", serif;
  font-size: 28rpx;
}

button {
  border: 0;
}

button::after {
  border: 0;
}

.sv-page {
  min-height: 100vh;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 44rpx 36rpx 132rpx;
  box-sizing: border-box;
  background: #f2f0e9;
}

.sv-page-tight {
  min-height: 100vh;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 32rpx 32rpx 132rpx;
  box-sizing: border-box;
  background: #f2f0e9;
}

.sv-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20rpx;
  margin-bottom: 28rpx;
}

.sv-kicker {
  display: block;
  font-family: "Courier New", monospace;
  font-size: 22rpx;
  line-height: 1.2;
  font-weight: 800;
  letter-spacing: 3rpx;
  color: rgba(26, 26, 26, 0.48);
  text-transform: uppercase;
}

.sv-title {
  display: block;
  margin-top: 6rpx;
  font-size: 44rpx;
  line-height: 1.12;
  font-weight: 800;
  font-style: italic;
  color: #1a2b48;
}

.sv-title-mark {
  color: #c4a052;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-style: normal;
  font-size: 28rpx;
}

.sv-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 42rpx;
  padding: 0 18rpx;
  border-radius: 999rpx;
  background: #1a2b48;
  border: 1rpx solid rgba(196, 160, 82, 0.35);
  color: #c4a052;
  font-family: "Courier New", monospace;
  font-size: 21rpx;
  font-weight: 800;
  letter-spacing: 1rpx;
}

.sv-card {
  background: #ffffff;
  border: 1rpx solid #dedacf;
  border-radius: 24rpx;
  padding: 26rpx;
  box-sizing: border-box;
}

.sv-cream-card {
  background: #f8f7f2;
  border: 1rpx solid #dedacf;
  border-radius: 24rpx;
  padding: 26rpx;
  box-sizing: border-box;
}

.sv-navy-card {
  position: relative;
  overflow: hidden;
  background: #1a2b48;
  border: 1rpx solid rgba(255, 255, 255, 0.08);
  border-radius: 32rpx;
  padding: 30rpx;
  box-sizing: border-box;
  color: #ffffff;
}

.sv-card,
.sv-cream-card,
.sv-navy-card,
.metric-card,
.insight-card,
.shortcut-card,
.spark-card,
.quick-card,
.fragment-card,
.source-card,
.draft-card,
.report-card,
.empty-card,
.persona-card,
.mode-card,
.session-card,
.identity-card,
.membership-card,
.menu-card,
.ocr-card,
.voice-card,
.input-card,
.result-card,
.save-card,
.content-card,
.info-card,
.card {
  transition: transform 140ms ease-out, box-shadow 140ms ease-out, border-color 140ms ease-out;
  transform-origin: center;
}

.sv-card:hover,
.sv-card:active,
.sv-cream-card:hover,
.sv-cream-card:active,
.metric-card:hover,
.metric-card:active,
.shortcut-card:hover,
.shortcut-card:active,
.spark-card:hover,
.spark-card:active,
.quick-card:hover,
.quick-card:active,
.fragment-card:hover,
.fragment-card:active,
.source-card:hover,
.source-card:active,
.draft-card:hover,
.draft-card:active,
.report-card:hover,
.report-card:active,
.empty-card:hover,
.empty-card:active,
.persona-card:hover,
.persona-card:active,
.mode-card:hover,
.mode-card:active,
.session-card:hover,
.session-card:active,
.membership-card:hover,
.membership-card:active,
.menu-card:hover,
.menu-card:active,
.ocr-card:hover,
.ocr-card:active,
.voice-card:hover,
.voice-card:active,
.input-card:hover,
.input-card:active,
.result-card:hover,
.result-card:active,
.save-card:hover,
.save-card:active,
.content-card:hover,
.content-card:active,
.info-card:hover,
.info-card:active,
.card:hover,
.card:active {
  transform: translateY(-2rpx);
  box-shadow: 0 12rpx 28rpx rgba(31, 41, 51, 0.10);
}

.sv-navy-card:hover,
.sv-navy-card:active,
.insight-card:hover,
.insight-card:active,
.identity-card:hover,
.identity-card:active {
  transform: translateY(-2rpx);
  box-shadow: 0 14rpx 32rpx rgba(26, 43, 72, 0.18);
}

.sv-section {
  display: block;
  margin: 30rpx 0 16rpx;
  font-family: "Courier New", monospace;
  font-size: 22rpx;
  line-height: 1.35;
  font-weight: 800;
  letter-spacing: 3rpx;
  color: rgba(26, 26, 26, 0.48);
  text-transform: uppercase;
}

.sv-label {
  display: block;
  font-size: 26rpx;
  line-height: 1.3;
  font-weight: 800;
  color: rgba(26, 26, 26, 0.62);
}

.sv-value {
  display: block;
  margin-top: 8rpx;
  font-size: 46rpx;
  line-height: 1;
  font-weight: 900;
  color: #1a2b48;
}

.sv-body {
  display: block;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-size: 28rpx;
  line-height: 1.58;
  color: rgba(26, 26, 26, 0.72);
}

.sv-caption {
  display: block;
  font-family: "Courier New", monospace;
  font-size: 22rpx;
  line-height: 1.35;
  color: rgba(26, 26, 26, 0.45);
}

.sv-row {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.sv-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16rpx;
}

.sv-grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 18rpx;
}

@media screen and (min-width: 960px) {
  .sv-page,
  .sv-page-tight {
    padding-left: 40px;
    padding-right: 40px;
  }

  .sv-card,
  .sv-cream-card,
  .sv-navy-card {
    border-radius: 16px;
  }
}

.sv-progress {
  height: 8rpx;
  margin-top: 18rpx;
  border-radius: 999rpx;
  overflow: hidden;
  background: #eae6db;
}

.sv-progress-fill {
  height: 100%;
  border-radius: 999rpx;
  background: #c4a052;
}

.sv-input,
.sv-textarea {
  width: 100%;
  box-sizing: border-box;
  background: #ffffff;
  border: 1rpx solid #dedacf;
  border-radius: 18rpx;
  padding: 20rpx 22rpx;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-size: 28rpx;
  color: #1a2b48;
}

.sv-textarea {
  min-height: 180rpx;
  line-height: 1.55;
}

.sv-chip-row {
  display: flex;
  gap: 12rpx;
  flex-wrap: nowrap;
}

.sv-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  min-height: 52rpx;
  padding: 0 20rpx;
  border-radius: 16rpx;
  border: 1rpx solid #dedacf;
  background: #ffffff;
  color: #1a2b48;
  font-size: 24rpx;
  font-weight: 800;
}

.sv-chip.active {
  background: #c4a052;
  border-color: #c4a052;
  color: #1a2b48;
}

.sv-tag {
  display: inline-flex;
  align-items: center;
  min-height: 34rpx;
  padding: 0 14rpx;
  border-radius: 10rpx;
  border: 1rpx solid rgba(222, 218, 207, 0.75);
  background: #f2f0e9;
  color: #1a2b48;
  font-family: "Courier New", monospace;
  font-size: 21rpx;
  font-weight: 800;
}

.sv-primary {
  min-height: 78rpx;
  border-radius: 18rpx;
  background: #1a2b48;
  color: #c4a052;
  font-size: 28rpx;
  font-weight: 900;
  line-height: 78rpx;
  border: 1rpx solid rgba(196, 160, 82, 0.3);
}

.sv-secondary {
  min-height: 72rpx;
  border-radius: 18rpx;
  background: #f8f7f2;
  color: #1a2b48;
  font-size: 26rpx;
  font-weight: 800;
  line-height: 72rpx;
  border: 1rpx solid #dedacf;
}

.iv-page {
  min-height: 100vh;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 40rpx 36rpx 132rpx;
  box-sizing: border-box;
  background: #f2f0e9;
}

.iv-title {
  display: block;
  color: #1a2b48;
  font-size: 44rpx;
  line-height: 1.18;
  font-weight: 900;
}

.iv-subtitle {
  display: block;
  margin-top: 10rpx;
  color: rgba(26, 26, 26, 0.66);
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-size: 28rpx;
  line-height: 1.55;
}

.iv-card {
  background: #ffffff;
  border: 1rpx solid #dedacf;
  border-radius: 20rpx;
  box-sizing: border-box;
}

.iv-card-padded {
  padding: 28rpx;
}

.iv-row,
.iv-between {
  display: flex;
  align-items: center;
  gap: 16rpx;
}

.iv-between {
  justify-content: space-between;
}

.iv-input,
.iv-textarea {
  width: 100%;
  box-sizing: border-box;
  border: 1rpx solid #dedacf;
  border-radius: 16rpx;
  background: #ffffff;
  color: #1a2b48;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-size: 28rpx;
  line-height: 1.55;
  padding: 18rpx 20rpx;
}

.iv-input {
  min-height: 76rpx;
}

.iv-textarea {
  min-height: 180rpx;
}

.iv-button,
.iv-outline-button {
  min-height: 84rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  border-radius: 18rpx;
  font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
  font-size: 28rpx;
  font-weight: 900;
  line-height: 1.25;
  text-align: center;
}

.iv-button {
  background: #1a2b48;
  color: #c4a052;
  border: 1rpx solid rgba(196, 160, 82, 0.3);
}

.iv-outline-button {
  background: #ffffff;
  color: #1a2b48;
  border: 1rpx solid #dedacf;
}

button[disabled] {
  opacity: 0.48;
}
</style>

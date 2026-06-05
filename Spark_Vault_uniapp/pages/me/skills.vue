<!-- pages/me/skills.vue — S6 个性化 / Skills 管理 -->
<template>
  <scroll-view class="page" scroll-y>
    <text class="page-sub">选择和自定义你的 AI 对话风格</text>

    <!-- Built-in mentors -->
    <text class="section-title">内置导师模板</text>
    <view class="group">
      <view class="skill-row" v-for="m in builtinSkills" :key="m.id">
        <text class="skill-emoji">{{ m.emoji }}</text>
        <view class="skill-info">
          <text class="skill-name">{{ m.name }}</text>
          <text class="skill-desc">{{ m.desc }}</text>
        </view>
        <view
          :class="['toggle', m.is_enabled ? 'on' : 'off']"
          @click="toggleBuiltin(m.id)"
        >
          <view class="toggle-thumb" />
        </view>
      </view>
    </view>

    <!-- Custom skills -->
    <text class="section-title">我的自定义 Skills</text>
    <view class="group">
      <view class="skill-row" v-for="s in customSkills" :key="s.id" @click="editSkill(s)">
        <text class="skill-emoji">{{ s.emoji || '🎯' }}</text>
        <view class="skill-info">
          <text class="skill-name">{{ s.name }}</text>
          <text class="skill-desc">{{ s.desc || s.prompt.slice(0, 40) }}</text>
        </view>
        <text class="skill-arrow">›</text>
      </view>

      <!-- Add new -->
      <view class="add-skill-row" @click="showCreateForm = true">
        <text class="add-skill-label">＋ 创建新 Skill</text>
      </view>
    </view>

    <!-- Create / Edit modal -->
    <view v-if="showCreateForm || editingSkill" class="modal-overlay" @click.self="closeForm">
      <view class="modal-box">
        <text class="modal-title">{{ editingSkill ? '编辑 Skill' : '创建新 Skill' }}</text>

        <view class="form-row">
          <text class="form-label">头像 Emoji</text>
          <input class="form-input short" v-model="form.emoji" placeholder="🎯" maxlength="2" />
        </view>
        <view class="form-row">
          <text class="form-label">名称 *</text>
          <input class="form-input" v-model="form.name" placeholder="例：我的创业导师" maxlength="20" />
        </view>
        <view class="form-row">
          <text class="form-label">简介</text>
          <input class="form-input" v-model="form.desc" placeholder="一句话描述风格" maxlength="40" />
        </view>
        <view class="form-row">
          <text class="form-label">风格描述（用于 AI）</text>
          <textarea
            class="form-textarea"
            v-model="form.prompt"
            placeholder="例：你是一位连续创业者，对早期产品的用户痛点极为敏感…"
            :maxlength="500"
          />
        </view>

        <view class="modal-actions">
          <text
            v-if="editingSkill"
            class="modal-delete"
            @click="deleteSkill"
          >删除</text>
          <text class="modal-cancel" @click="closeForm">取消</text>
          <text class="modal-save" @click="saveSkill">保存</text>
        </view>
      </view>
    </view>
  </scroll-view>
</template>

<script>
import { getSkills, toggleBuiltin, createSkill, updateSkill, deleteSkill } from '@/services/skillsService.js'

export default {
  data() {
    return {
      builtinSkills: [],
      customSkills: [],
      showCreateForm: false,
      editingSkill: null,
      form: { emoji: '🎯', name: '', desc: '', prompt: '' }
    }
  },
  onShow() {
    this.loadSkills()
  },
  methods: {
    loadSkills() {
      const all = getSkills()
      this.builtinSkills = all.filter((s) => s.is_builtin)
      this.customSkills = all.filter((s) => !s.is_builtin)
    },
    toggleBuiltin(id) {
      toggleBuiltin(id)
      this.loadSkills()
    },
    editSkill(skill) {
      this.editingSkill = skill
      this.form = {
        emoji: skill.emoji || '🎯',
        name: skill.name,
        desc: skill.desc || '',
        prompt: skill.prompt || ''
      }
    },
    closeForm() {
      this.showCreateForm = false
      this.editingSkill = null
      this.form = { emoji: '🎯', name: '', desc: '', prompt: '' }
    },
    saveSkill() {
      if (!this.form.name.trim()) {
        uni.showToast({ title: '名称不能为空', icon: 'none' })
        return
      }
      try {
        if (this.editingSkill) {
          updateSkill(this.editingSkill.id, this.form)
        } else {
          createSkill(this.form)
        }
        this.closeForm()
        this.loadSkills()
        uni.showToast({ title: '已保存', icon: 'success', duration: 1000 })
      } catch (err) {
        uni.showToast({ title: err.message || '保存失败', icon: 'none' })
      }
    },
    deleteSkill() {
      if (!this.editingSkill) return
      uni.showModal({
        title: '删除 Skill',
        content: `删除「${this.editingSkill.name}」？`,
        confirmText: '删除',
        confirmColor: '#ba1a1a',
        success: (res) => {
          if (res.confirm) {
            deleteSkill(this.editingSkill.id)
            this.closeForm()
            this.loadSkills()
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.page { background: #fbf9f6; padding: 24rpx; }
.page-sub { display: block; font-size: 26rpx; color: #49454f; margin-bottom: 28rpx; }

.section-title { display: block; font-size: 26rpx; font-weight: 700; color: #49454f; margin-bottom: 14rpx; margin-top: 8rpx; }
.group { background: #ffffff; border-radius: 24rpx; margin-bottom: 28rpx; overflow: hidden; }

.skill-row { display: flex; align-items: center; gap: 16rpx; padding: 22rpx 28rpx; border-bottom: 2rpx solid #f5f2ee; }
.skill-row:last-child { border-bottom: none; }
.skill-emoji { font-size: 36rpx; width: 44rpx; }
.skill-info { flex: 1; }
.skill-name { display: block; font-size: 28rpx; font-weight: 600; color: #1c1b1f; }
.skill-desc { display: block; font-size: 22rpx; color: #49454f; margin-top: 4rpx; }
.skill-arrow { font-size: 28rpx; color: #a39e97; }

/* Toggle */
.toggle { width: 88rpx; height: 48rpx; border-radius: 24rpx; transition: background 0.2s; display: flex; align-items: center; padding: 6rpx; flex-shrink: 0; }
.toggle.on { background: #004a77; justify-content: flex-end; }
.toggle.off { background: #d8d4ce; justify-content: flex-start; }
.toggle-thumb { width: 36rpx; height: 36rpx; background: #ffffff; border-radius: 18rpx; }

/* Add skill */
.add-skill-row { padding: 24rpx 28rpx; border-top: 2rpx dashed #d8d4ce; }
.add-skill-label { font-size: 28rpx; color: #004a77; font-weight: 600; }

/* Modal */
.modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 200; display: flex; align-items: flex-end; }
.modal-box { background: #ffffff; border-radius: 32rpx 32rpx 0 0; width: 100%; padding: 32rpx 28rpx 48rpx; max-height: 90vh; overflow-y: auto; }
.modal-title { display: block; font-size: 32rpx; font-weight: 700; color: #1c1b1f; margin-bottom: 28rpx; }

.form-row { margin-bottom: 20rpx; }
.form-label { display: block; font-size: 24rpx; color: #49454f; margin-bottom: 8rpx; }
.form-input { width: 100%; font-size: 28rpx; color: #1c1b1f; background: #f5f2ee; border-radius: 14rpx; padding: 14rpx 16rpx; }
.form-input.short { width: 100rpx; }
.form-textarea { width: 100%; font-size: 26rpx; color: #1c1b1f; background: #f5f2ee; border-radius: 14rpx; padding: 14rpx 16rpx; min-height: 140rpx; line-height: 1.6; }

.modal-actions { display: flex; align-items: center; justify-content: flex-end; gap: 24rpx; margin-top: 28rpx; }
.modal-delete { font-size: 28rpx; color: #ba1a1a; margin-right: auto; }
.modal-cancel { font-size: 28rpx; color: #49454f; }
.modal-save { font-size: 28rpx; color: #004a77; font-weight: 700; }
</style>

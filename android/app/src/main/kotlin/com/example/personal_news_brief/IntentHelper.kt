package com.example.personal_news_brief

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.text.TextUtils
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Intent辅助类
 * 用于启动外部编辑器应用，如Joplin、Markor等
 */
class IntentHelper {
    
    companion object {
        
        /**
         * 启动Joplin应用
         * 
         * @param context 上下文
         * @param title 笔记标题
         * @param body 笔记内容
         * @return 是否成功启动Joplin
         */
        fun launchJoplin(context: Context, title: String, body: String): Boolean {
            return try {
                // 检查Joplin是否已安装
                if (!isJoplinInstalled(context)) {
                    return false
                }
                
                // 构建Joplin深度链接
                val encodedTitle = Uri.encode(title)
                val encodedBody = Uri.encode(body)
                val joplinUri = "joplin://x-callback-url/newNote?title=$encodedTitle&body=$encodedBody"
                
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(joplinUri))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                
                // 检查是否有应用可以处理此Intent
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
        
        /**
         * 启动Markor应用
         * 
         * @param context 上下文
         * @param title 文件名（不含扩展名）
         * @param content 文件内容
         * @return 是否成功启动Markor
         */
        fun launchMarkor(context: Context, title: String, content: String): Boolean {
            return try {
                // 检查Markor是否已安装
                if (!isMarkorInstalled(context)) {
                    return false
                }
                
                // 创建临时文件
                val tempFile = createTempMarkdownFile(context, title, content) ?: return false
                
                // 获取临时文件的Content URI
                val fileUri = FileProvider.getUriForFile(
                    context,
                    "${context.packageName}.fileprovider",
                    tempFile
                )
                
                // 构建Markor深度链接
                val encodedTitle = Uri.encode(title)
                val encodedContent = Uri.encode(content)
                val markorUri = "markor://?path=$encodedTitle.md&content=$encodedContent"
                
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(markorUri))
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                
                // 检查是否有应用可以处理此Intent
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    true
                } else {
                    // 如果深度链接失败，尝试使用文件URI
                    launchMarkorWithFile(context, fileUri)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
        
        /**
         * 使用文件URI启动Markor
         */
        private fun launchMarkorWithFile(context: Context, fileUri: Uri): Boolean {
            return try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(fileUri, "text/markdown")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                
                // 检查是否有应用可以处理此Intent
                if (intent.resolveActivity(context.packageManager) != null) {
                    context.startActivity(intent)
                    true
                } else {
                    false
                }
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
        
        /**
         * 检查Joplin是否已安装
         * 
         * @param context 上下文
         * @return 是否已安装Joplin
         */
        fun isJoplinInstalled(context: Context): Boolean {
            return try {
                val packageManager = context.packageManager
                val intent = packageManager.getLaunchIntentForPackage("net.cozic.joplin")
                intent != null
            } catch (e: Exception) {
                false
            }
        }
        
        /**
         * 检查Markor是否已安装
         * 
         * @param context 上下文
         * @return 是否已安装Markor
         */
        fun isMarkorInstalled(context: Context): Boolean {
            return try {
                val packageManager = context.packageManager
                val intent = packageManager.getLaunchIntentForPackage("net.gsantner.markor")
                intent != null
            } catch (e: Exception) {
                false
            }
        }
        
        /**
         * 获取已安装的外部编辑器列表
         * 
         * @param context 上下文
         * @return 已安装的编辑器名称列表
         */
        fun getInstalledEditors(context: Context): List<String> {
            val installed = mutableListOf<String>()
            
            if (isJoplinInstalled(context)) {
                installed.add("Joplin")
            }
            
            if (isMarkorInstalled(context)) {
                installed.add("Markor")
            }
            
            return installed
        }
        
        /**
         * 创建临时Markdown文件
         * 
         * @param context 上下文
         * @param title 文件标题
         * @param content 文件内容
         * @return 临时文件对象，如果创建失败则返回null
         */
        private fun createTempMarkdownFile(context: Context, title: String, content: String): File? {
            return try {
                // 创建临时目录
                val tempDir = File(context.cacheDir, "temp_markdown")
                if (!tempDir.exists()) {
                    tempDir.mkdirs()
                }
                
                // 创建临时文件
                val fileName = "${title.replace(Regex("[^a-zA-Z0-9\\-_\\u4e00-\\u9fa5]"), "_")}.md"
                val tempFile = File(tempDir, fileName)
                
                // 写入内容
                FileOutputStream(tempFile).use { outputStream ->
                    outputStream.write(content.toByteArray(Charsets.UTF_8))
                }
                
                tempFile
            } catch (e: IOException) {
                e.printStackTrace()
                null
            }
        }
        
        /**
         * 启动应用商店下载指定应用
         * 
         * @param context 上下文
         * @param packageName 应用包名
         */
        fun launchAppStore(context: Context, packageName: String) {
            try {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    data = Uri.parse("market://details?id=$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                
                // 如果没有Google Play，尝试使用浏览器
                if (intent.resolveActivity(context.packageManager) == null) {
                    data = Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
                }
                
                context.startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        /**
         * 分享文本内容
         * 
         * @param context 上下文
         * @param title 分享标题
         * @param content 分享内容
         */
        fun shareText(context: Context, title: String, content: String) {
            try {
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_SUBJECT, title)
                    putExtra(Intent.EXTRA_TEXT, content)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                
                // 使用选择器让用户选择分享应用
                val chooser = Intent.createChooser(intent, "分享到")
                context.startActivity(chooser)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
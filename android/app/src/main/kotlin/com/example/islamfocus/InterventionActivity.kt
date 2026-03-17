package com.example.islamfocus

import android.animation.ValueAnimator
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.CountDownTimer
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.LinearInterpolator
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class InterventionActivity : AppCompatActivity() {

    private var blockedPackage = ""
    private var mode = "standard_dhikr"
    private var dhikrText = "SubhanAllah"
    private var dhikrCount = 0
    private var durationSeconds = 10
    private var fillColorHex = "#1DB954"
    private var countDownTimer: CountDownTimer? = null
    private lateinit var prefs: SharedPreferences
    private lateinit var quranPrefs: SharedPreferences
    private lateinit var flutterPrefs: SharedPreferences

    private var ayatCount = 0
    private var currentAyat: Ayat? = null
    private var quranTimerDone = false

    private var arabicText: TextView? = null
    private var translationText: TextView? = null
    private var surahRefText: TextView? = null
    private var wisdomText: TextView? = null
    private var ayatCounterText: TextView? = null
    private var buttonsContainer: LinearLayout? = null
    private var reflectText: TextView? = null
    private var prevBtn: LinearLayout? = null
    private var nextBtn: LinearLayout? = null

    private var translationLanguage = "English"
    private var showTranslation = true

    private var fillColor: Int = Color.parseColor("#1DB954")

    private val wisdomQuotes = arrayOf(
        "A gentle reminder about focus and company.",
        "Reflect on the blessings around you.",
        "Patience is the key to paradise.",
        "Every moment is an opportunity for dhikr.",
        "Turn to Allah before you return to Allah.",
        "The best of you are those who learn the Quran and teach it.",
        "Remember, this world is temporary.",
        "Your heart finds peace in the remembrance of Allah.",
        "Be grateful for what you have.",
        "Seek knowledge from the cradle to the grave."
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        showLoadingScreen()

        prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        quranPrefs = getSharedPreferences("islam_focus_quran", MODE_PRIVATE)
        flutterPrefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)

        blockedPackage = intent.getStringExtra("blocked_package") ?: ""
        mode = intent.getStringExtra("mode") ?: "standard_dhikr"
        dhikrText = intent.getStringExtra("dhikr_text") ?: "SubhanAllah"
        durationSeconds = intent.getIntExtra("dhikr_limit", 10)
        fillColorHex = intent.getStringExtra("fill_color") ?: "#1DB954"

        fillColor = try { Color.parseColor(fillColorHex) } catch (e: Exception) { Color.parseColor("#1DB954") }

        translationLanguage = flutterPrefs.getString("flutter.verse_language", "English") ?: "English"
        showTranslation = flutterPrefs.getBoolean("flutter.verse_show_translation", true)

        when (mode) {
            "quran_verse" -> {
                val cachedAyat = QuranLoader.getCurrentAyat(quranPrefs)
                if (cachedAyat.arabic != "Loading..." && cachedAyat.arabic.isNotEmpty()) {
                    currentAyat = cachedAyat
                    buildQuranScreen()
                    Thread {
                        QuranLoader.preloadNextSurahs(quranPrefs, cachedAyat.surahNumber, 3)
                    }.start()
                } else {
                    Thread {
                        QuranLoader.downloadAndCacheSurah(quranPrefs, quranPrefs.getInt("quran_current_surah", 1))
                        runOnUiThread {
                            currentAyat = QuranLoader.getCurrentAyat(quranPrefs)
                            buildQuranScreen()
                        }
                    }.start()
                }
            }
            else -> showDhikrScreen()
        }
    }

    private fun fillColorWithAlpha(alpha: Int): Int {
        return Color.argb(alpha, Color.red(fillColor), Color.green(fillColor), Color.blue(fillColor))
    }

    private fun showLoadingScreen() {
        val root = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(-1, -1)
            setBackgroundColor(Color.WHITE)
        }
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(-1, -1)
        }
        val iconBg = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(80), dp(80)).apply { gravity = Gravity.CENTER_HORIZONTAL }
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.parseColor("#1DB954")) }
        }
        iconBg.addView(TextView(this).apply {
            text = "\u262A"; setTextSize(TypedValue.COMPLEX_UNIT_SP, 36f); setTextColor(Color.WHITE)
            gravity = Gravity.CENTER; layoutParams = FrameLayout.LayoutParams(-1, -1)
        })
        layout.addView(iconBg)
        layout.addView(sp(24))
        layout.addView(txt("Islam Focus", 22f, "#1DB954", true))
        layout.addView(sp(8))
        layout.addView(txt("Preparing your mindful pause...", 14f, "#999999", false))
        layout.addView(sp(32))
        layout.addView(ProgressBar(this).apply {
            indeterminateTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#1DB954"))
            layoutParams = LinearLayout.LayoutParams(dp(40), dp(40)).apply { gravity = Gravity.CENTER_HORIZONTAL }
        })
        root.addView(layout)
        setContentView(root)
    }

    private fun saveDhikrData() {
        if (dhikrCount <= 0) return
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val now = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).format(Date())
        prefs.edit().putLong("flutter.total_dhikr_count", prefs.getLong("flutter.total_dhikr_count", 0) + dhikrCount).apply()
        val arr = try { JSONArray(prefs.getString("flutter.dhikr_logs_local", "[]")) } catch (e: Exception) { JSONArray() }
        arr.put(JSONObject().apply { put("count", dhikrCount); put("dhikr_type", dhikrText); put("logged_at", today); put("created_at", now) })
        prefs.edit().putString("flutter.dhikr_logs_local", arr.toString()).apply()
        prefs.edit().putLong("flutter.total_sessions", prefs.getLong("flutter.total_sessions", 0) + 1).apply()
        updateStreak(today)
    }

    private fun saveAyatData() {
        if (ayatCount <= 0) return
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(Date())
        val now = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).format(Date())
        prefs.edit().putLong("flutter.total_ayat_recitation", prefs.getLong("flutter.total_ayat_recitation", 0) + ayatCount).apply()
        val arr = try { JSONArray(prefs.getString("flutter.ayat_logs_local", "[]")) } catch (e: Exception) { JSONArray() }
        arr.put(JSONObject().apply { put("count", ayatCount); put("logged_at", today); put("created_at", now) })
        prefs.edit().putString("flutter.ayat_logs_local", arr.toString()).apply()
        prefs.edit().putLong("flutter.total_sessions", prefs.getLong("flutter.total_sessions", 0) + 1).apply()
        updateStreak(today)
    }

    private fun updateStreak(today: String) {
        val last = prefs.getString("flutter.last_active_date", "") ?: ""
        if (last != today) {
            val cal = Calendar.getInstance(); cal.add(Calendar.DAY_OF_YEAR, -1)
            val yesterday = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(cal.time)
            val s = prefs.getLong("flutter.current_streak", 0)
            prefs.edit().putLong("flutter.current_streak", if (last == yesterday) s + 1 else 1).apply()
            prefs.edit().putString("flutter.last_active_date", today).apply()
        }
    }

    private fun showDhikrScreen() {
        val root = FrameLayout(this).apply { layoutParams = FrameLayout.LayoutParams(-1, -1) }

        root.addView(View(this).apply {
            layoutParams = FrameLayout.LayoutParams(-1, -1)
            setBackgroundColor(Color.argb(30, Color.red(fillColor), Color.green(fillColor), Color.blue(fillColor)))
        })

        val fillView = SmoothFillView(this, durationSeconds).apply {
            this.fillColor = fillColorWithAlpha(100)
        }
        fillView.layoutParams = FrameLayout.LayoutParams(-1, -1)
        root.addView(fillView)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
            setPadding(dp(32), 0, dp(32), 0)
            layoutParams = FrameLayout.LayoutParams(-1, -1)
        }

        layout.addView(txt("SAY", 14f, fillColorHex, true, 0.3f))
        layout.addView(sp(12))
        layout.addView(txt(dhikrText, 28f, "#1A1A1A", true))
        layout.addView(sp(10))
        layout.addView(txt(arabicDhikr(dhikrText), 24f, "#333333", false))
        layout.addView(sp(8))
        layout.addView(itxt(meaningDhikr(dhikrText), 13f, "#666666"))
        layout.addView(sp(40))

        val ct = txt("0", 44f, "#FFFFFF", true)
        val tl = txt("TAP", 13f, "#BBFFFFFF", true, 0.15f)
        val cc = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(-1, -1)
            addView(ct); addView(tl)
        }
        val circle = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(150), dp(150)).apply { gravity = Gravity.CENTER_HORIZONTAL }
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(fillColor) }
            elevation = dp(12).toFloat()
            addView(cc)
            setOnClickListener { dhikrCount++; ct.text = "$dhikrCount" }
        }
        layout.addView(circle)
        layout.addView(sp(20))
        layout.addView(txt("Tap the circle for each repetition", 13f, "#777777", false))

        root.addView(layout)
        setContentView(root)
        fillView.startAnimation()

        countDownTimer = object : CountDownTimer(durationSeconds * 1000L, 1000) {
            override fun onTick(m: Long) {}
            override fun onFinish() { fillView.stopAnimation(); saveDhikrData(); showComplete() }
        }.start()
    }

    private fun buildQuranScreen() {
        val ayat = currentAyat ?: return
        val appName = getAppName(blockedPackage)

        val root = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(-1, -1)
            setBackgroundColor(Color.WHITE)
        }

        val fillView = SmoothFillView(this, durationSeconds).apply {
            this.fillColor = fillColorWithAlpha(25)
        }
        fillView.layoutParams = FrameLayout.LayoutParams(-1, -1)
        root.addView(fillView)

        val scrollView = ScrollView(this).apply {
            layoutParams = FrameLayout.LayoutParams(-1, -1)
            isFillViewport = true
        }

        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(16), dp(24), dp(20))
        }

        mainLayout.addView(TextView(this).apply {
            text = "Before opening ${appName}..."
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTextColor(Color.parseColor("#AAAAAA"))
            gravity = Gravity.CENTER
        })
        mainLayout.addView(sp(20))

        arabicText = TextView(this).apply {
            text = ayat.arabic
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            setTextColor(Color.parseColor("#1A1A1A"))
            gravity = Gravity.CENTER
            setLineSpacing(dp(16).toFloat(), 1f)
            typeface = Typeface.create("serif", Typeface.BOLD)
        }
        mainLayout.addView(arabicText!!)
        mainLayout.addView(sp(20))

        if (showTranslation) {
            val transStr = if (translationLanguage == "Urdu") ayat.urdu else ayat.english
            translationText = TextView(this).apply {
                text = transStr
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setTextColor(Color.parseColor("#444444"))
                gravity = Gravity.CENTER
                setLineSpacing(dp(4).toFloat(), 1f)
            }
            mainLayout.addView(translationText!!)
        } else {
            translationText = TextView(this).apply {
                text = "Translation is off \u00B7 Enable in Settings"
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                setTextColor(Color.parseColor("#CCCCCC"))
                gravity = Gravity.CENTER
            }
            mainLayout.addView(translationText!!)
        }
        mainLayout.addView(sp(14))

        surahRefText = TextView(this).apply {
            text = "Surah ${ayat.surahName} \u00B7 Verse ${ayat.ayatNumber}"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setTextColor(Color.parseColor("#555555"))
            gravity = Gravity.CENTER
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }
        mainLayout.addView(surahRefText!!)
        mainLayout.addView(sp(8))

        val randomWisdom = wisdomQuotes[(System.currentTimeMillis() % wisdomQuotes.size).toInt()]
        wisdomText = TextView(this).apply {
            text = randomWisdom
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(Color.parseColor("#AAAAAA"))
            gravity = Gravity.CENTER
            setTypeface(typeface, Typeface.ITALIC)
        }
        mainLayout.addView(wisdomText!!)
        mainLayout.addView(sp(24))

        mainLayout.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(-1, dp(1))
            setBackgroundColor(Color.parseColor("#EEEEEE"))
        })
        mainLayout.addView(sp(16))

        val navRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(-1, -2)
        }

        prevBtn = makeNavBtnWithLabel("Previous", false)
        prevBtn!!.setOnClickListener { onPrevAyat() }
        navRow.addView(prevBtn!!)

        navRow.addView(View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(30), 0)
        })

        nextBtn = makeNavBtnWithLabel("Next", true)
        nextBtn!!.setOnClickListener { onNextAyat() }
        navRow.addView(nextBtn!!)

        mainLayout.addView(navRow)
        mainLayout.addView(sp(20))

        buttonsContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER_HORIZONTAL
            visibility = View.GONE
            layoutParams = LinearLayout.LayoutParams(-1, -2)
        }

        buttonsContainer!!.addView(Button(this).apply {
            text = "Continue to $appName"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f); setTextColor(Color.WHITE)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD); isAllCaps = false
            background = GradientDrawable().apply { setColor(fillColor); cornerRadius = dp(28).toFloat() }
            layoutParams = LinearLayout.LayoutParams(-1, dp(52)); elevation = dp(2).toFloat()
            setOnClickListener { saveAyatData(); openApp() }
        })
        buttonsContainer!!.addView(sp(12))

        buttonsContainer!!.addView(TextView(this).apply {
            text = "I don't want to open $appName"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(Color.parseColor("#4285F4"))
            gravity = Gravity.CENTER
            setPadding(0, dp(6), 0, dp(6))
            setOnClickListener { saveAyatData(); goHome() }
        })

        mainLayout.addView(buttonsContainer!!)

        reflectText = TextView(this).apply {
            text = "Take a moment to reflect"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            setTextColor(Color.parseColor("#BBBBBB"))
            gravity = Gravity.CENTER
        }
        mainLayout.addView(reflectText!!)

        scrollView.addView(mainLayout)
        root.addView(scrollView)
        setContentView(root)

        fillView.startAnimation()

        countDownTimer = object : CountDownTimer(durationSeconds * 1000L, 1000) {
            override fun onTick(m: Long) {}
            override fun onFinish() {
                quranTimerDone = true
                fillView.stopAnimation()
                reflectText?.visibility = View.GONE
                buttonsContainer?.visibility = View.VISIBLE
            }
        }.start()
    }

    private fun makeNavBtnWithLabel(label: String, active: Boolean): LinearLayout {
        val color = if (active) fillColor else Color.parseColor("#CCCCCC")
        val borderHex = if (active) fillColorHex else "#DDDDDD"
        val arrowText = if (label == "Next") "\u25B6" else "\u25C0"

        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(-2, -2)

            val circle = FrameLayout(this@InterventionActivity).apply {
                layoutParams = LinearLayout.LayoutParams(dp(48), dp(48)).apply { gravity = Gravity.CENTER_HORIZONTAL }
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setStroke(dp(2), Color.parseColor(borderHex))
                    setColor(Color.WHITE)
                }
                if (!active) alpha = 0.5f
            }
            circle.addView(TextView(this@InterventionActivity).apply {
                text = arrowText
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                setTextColor(color)
                gravity = Gravity.CENTER
                layoutParams = FrameLayout.LayoutParams(-1, -1)
            })
            addView(circle)

            addView(TextView(this@InterventionActivity).apply {
                text = label
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
                setTextColor(if (active) Color.parseColor("#666666") else Color.parseColor("#CCCCCC"))
                gravity = Gravity.CENTER
                setPadding(0, dp(4), 0, 0)
            })
        }
    }

    private fun onNextAyat() {
        ayatCount++
        currentAyat = QuranLoader.moveToNextAndGet(quranPrefs)
        val ayat = currentAyat ?: return

        if (ayat.arabic == "Loading..." || ayat.arabic.isEmpty()) {
            arabicText?.text = "Loading..."
            translationText?.text = ""
            Thread {
                QuranLoader.downloadAndCacheSurah(quranPrefs, ayat.surahNumber)
                val loaded = QuranLoader.getCurrentAyat(quranPrefs)
                runOnUiThread { updateAyatDisplay(loaded); currentAyat = loaded }
                val next = if (ayat.surahNumber >= 114) 1 else ayat.surahNumber + 1
                QuranLoader.downloadAndCacheSurah(quranPrefs, next)
            }.start()
        } else {
            updateAyatDisplay(ayat)
            Thread {
                val next = if (ayat.surahNumber >= 114) 1 else ayat.surahNumber + 1
                QuranLoader.downloadAndCacheSurah(quranPrefs, next)
            }.start()
        }

        enableNavBtn(prevBtn, true)
    }

    private fun onPrevAyat() {
        if (ayatCount <= 0) return
        val ayatNum = quranPrefs.getInt("quran_current_ayat", 1)
        if (ayatNum <= 1) return

        quranPrefs.edit().putInt("quran_current_ayat", ayatNum - 1).apply()
        currentAyat = QuranLoader.getCurrentAyat(quranPrefs)
        val ayat = currentAyat ?: return

        if (ayat.arabic == "Loading..." || ayat.arabic.isEmpty()) {
            arabicText?.text = "Loading..."
            translationText?.text = ""
            Thread {
                QuranLoader.downloadAndCacheSurah(quranPrefs, ayat.surahNumber)
                val loaded = QuranLoader.getCurrentAyat(quranPrefs)
                runOnUiThread { updateAyatDisplay(loaded); currentAyat = loaded }
            }.start()
        } else {
            updateAyatDisplay(ayat)
        }

        ayatCount--
        if (ayatCount <= 0) {
            enableNavBtn(prevBtn, false)
        }
    }

    private fun enableNavBtn(btn: LinearLayout?, active: Boolean) {
        if (btn == null) return
        val circle = btn.getChildAt(0) as? FrameLayout ?: return
        val arrow = circle.getChildAt(0) as? TextView ?: return
        val label = btn.getChildAt(1) as? TextView ?: return

        circle.alpha = if (active) 1f else 0.5f
        circle.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setStroke(dp(2), if (active) fillColor else Color.parseColor("#DDDDDD"))
            setColor(Color.WHITE)
        }
        arrow.setTextColor(if (active) fillColor else Color.parseColor("#CCCCCC"))
        label.setTextColor(if (active) Color.parseColor("#666666") else Color.parseColor("#CCCCCC"))
    }

    private fun updateAyatDisplay(ayat: Ayat) {
        arabicText?.text = ayat.arabic
        surahRefText?.text = "Surah ${ayat.surahName} \u00B7 Verse ${ayat.ayatNumber}"
        if (showTranslation) {
            translationText?.text = if (translationLanguage == "Urdu") ayat.urdu else ayat.english
        }
        val randomWisdom = wisdomQuotes[(System.currentTimeMillis() % wisdomQuotes.size).toInt()]
        wisdomText?.text = randomWisdom
    }

    private fun showComplete() {
        val app = getAppName(blockedPackage)
        val l = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
            setPadding(dp(32), 0, dp(32), dp(40))
            layoutParams = FrameLayout.LayoutParams(-1, -1)
            setBackgroundColor(Color.WHITE)
        }
        l.addView(txt("\u2705", 48f, "#000000", false))
        l.addView(sp(20))
        if (dhikrCount > 0) {
            l.addView(txt("$dhikrCount", 48f, fillColorHex, true))
            l.addView(sp(8))
            l.addView(txt("${dhikrText}s said", 16f, "#666666", false))
        } else {
            l.addView(txt("Time's up!", 32f, fillColorHex, true))
        }
        l.addView(sp(50))
        l.addView(Button(this).apply {
            text = "I don't want to open $app"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f); setTextColor(Color.WHITE)
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD); isAllCaps = false
            background = GradientDrawable().apply { setColor(fillColor); cornerRadius = dp(28).toFloat() }
            layoutParams = LinearLayout.LayoutParams(-1, dp(56)); elevation = dp(4).toFloat()
            setOnClickListener { goHome() }
        })
        l.addView(sp(16))
        l.addView(TextView(this).apply {
            text = "Continue to $app"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(Color.parseColor("#888888"))
            gravity = Gravity.CENTER
            setPadding(0, dp(12), 0, dp(12))
            setOnClickListener { openApp() }
        })
        setContentView(l)
    }

    inner class SmoothFillView(ctx: android.content.Context, private val sec: Int) : View(ctx) {
        var fillColor: Int = Color.parseColor("#401DB954")
        private val p = Paint(Paint.ANTI_ALIAS_FLAG)
        private var fl = 0f
        private var a: ValueAnimator? = null

        fun startAnimation() {
            a = ValueAnimator.ofFloat(0f, 1f, 0f).apply {
                duration = sec * 1000L
                interpolator = LinearInterpolator()
                addUpdateListener { fl = it.animatedValue as Float; invalidate() }
                start()
            }
        }

        fun stopAnimation() { a?.cancel() }

        override fun onDraw(c: Canvas) {
            super.onDraw(c)
            val h = height.toFloat()
            p.color = fillColor; p.style = Paint.Style.FILL
            c.drawRect(0f, h - (fl * h), width.toFloat(), h, p)
        }
    }

    private fun txt(t: String, s: Float, c: String, b: Boolean, ls: Float = 0f) = TextView(this).apply {
        text = t; setTextSize(TypedValue.COMPLEX_UNIT_SP, s)
        setTextColor(try { Color.parseColor(c) } catch (e: Exception) { Color.parseColor("#1DB954") })
        if (b) typeface = Typeface.create("sans-serif", Typeface.BOLD); gravity = Gravity.CENTER
        if (ls > 0) letterSpacing = ls
    }

    private fun itxt(t: String, s: Float, c: String) = TextView(this).apply {
        text = t; setTextSize(TypedValue.COMPLEX_UNIT_SP, s); setTextColor(Color.parseColor(c))
        setTypeface(typeface, Typeface.ITALIC); gravity = Gravity.CENTER
    }

    private fun sp(d: Int): View = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(-1, dp(d))
    }

    private fun dp(v: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics
    ).toInt()

    private fun openApp() {
        val servicePrefs = getSharedPreferences("islam_focus_prefs", MODE_PRIVATE)
        servicePrefs.edit().putString("allowed_until_leave", blockedPackage).apply()
        packageManager.getLaunchIntentForPackage(blockedPackage)?.let {
            it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            it.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(it)
        }
        finishAndRemoveTask()
    }

    private fun goHome() {
        startActivity(Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME); flags = Intent.FLAG_ACTIVITY_NEW_TASK
        })
        finishAndRemoveTask()
    }

    private fun getAppName(p: String): String = try {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(p, 0)).toString()
    } catch (e: Exception) {
        p.split(".").lastOrNull()?.replaceFirstChar { it.uppercase() } ?: "App"
    }

    private fun arabicDhikr(t: String) = when (t) {
        "SubhanAllah" -> "\u0633\u064F\u0628\u0652\u062D\u064E\u0627\u0646\u064E \u0627\u0644\u0644\u0651\u064E\u0647\u0650"
        "Alhamdulillah" -> "\u0627\u0644\u0652\u062D\u064E\u0645\u0652\u062F\u064F \u0644\u0650\u0644\u0651\u064E\u0647\u0650"
        "Allahu Akbar" -> "\u0627\u0644\u0644\u0651\u064E\u0647\u064F \u0623\u064E\u0643\u0652\u0628\u064E\u0631\u064F"
        "La ilaha illallah" -> "\u0644\u064E\u0627 \u0625\u0650\u0644\u064E\u0670\u0647\u064E \u0625\u0650\u0644\u0651\u064E\u0627 \u0627\u0644\u0644\u0651\u064E\u0647\u064F"
        "Astaghfirullah" -> "\u0623\u064E\u0633\u0652\u062A\u064E\u063A\u0652\u0641\u0650\u0631\u064F \u0627\u0644\u0644\u0651\u064E\u0647\u064E"
        "SubhanAllahi wa bihamdihi" -> "\u0633\u064F\u0628\u0652\u062D\u064E\u0627\u0646\u064E \u0627\u0644\u0644\u0651\u064E\u0647\u0650 \u0648\u064E\u0628\u0650\u062D\u064E\u0645\u0652\u062F\u0650\u0647\u0650"
        else -> "\u0633\u064F\u0628\u0652\u062D\u064E\u0627\u0646\u064E \u0627\u0644\u0644\u0651\u064E\u0647\u0650"
    }

    private fun meaningDhikr(t: String) = when (t) {
        "SubhanAllah" -> "\"Glory be to Allah\""
        "Alhamdulillah" -> "\"All praise is due to Allah\""
        "Allahu Akbar" -> "\"Allah is the Greatest\""
        "La ilaha illallah" -> "\"There is no god but Allah\""
        "Astaghfirullah" -> "\"I seek forgiveness from Allah\""
        "SubhanAllahi wa bihamdihi" -> "\"Glory be to Allah and His praise\""
        else -> "\"Glory be to Allah\""
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val servicePrefs = getSharedPreferences("islam_focus_prefs", MODE_PRIVATE)
        servicePrefs.edit().putString("allowed_until_leave", blockedPackage).apply()
        if (mode == "quran_verse") saveAyatData()
        if (mode == "standard_dhikr") saveDhikrData()
        goHome()
    }
}
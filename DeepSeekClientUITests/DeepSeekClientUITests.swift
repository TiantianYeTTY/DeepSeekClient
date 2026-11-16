// Designed by TiantianYe
import XCTest

final class DeepSeekClientUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureScreensAndChipToggle() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["晚上好，有什么我能帮你的吗?"].waitForExistence(timeout: 8)
                || app.staticTexts["早上好，有什么我能帮你的吗?"].waitForExistence(timeout: 2)
                || app.staticTexts["下午好，有什么我能帮你的吗?"].waitForExistence(timeout: 2),
            "首页问候语未出现"
        )
        try capture(app, name: "home_v2")

        // 验证深度思考 / 智能搜索 chip 可真实切换（auxiliary value 变化）
        let deepChip = app.buttons["深度思考"]
        XCTAssertTrue(deepChip.waitForExistence(timeout: 5), "深度思考按钮未找到")
        XCTAssertEqual(deepChip.value as? String, "已关闭", "深度思考初始应为关闭")
        deepChip.tap()
        Thread.sleep(forTimeInterval: 0.4)
        XCTAssertEqual(deepChip.value as? String, "已开启", "深度思考点击后应为开启")

        let webChip = app.buttons["智能搜索"]
        XCTAssertTrue(webChip.waitForExistence(timeout: 5), "智能搜索按钮未找到")
        XCTAssertEqual(webChip.value as? String, "已关闭", "智能搜索初始应为关闭")
        webChip.tap()
        Thread.sleep(forTimeInterval: 0.4)
        XCTAssertEqual(webChip.value as? String, "已开启", "智能搜索点击后应为开启")
        try capture(app, name: "chips_on_v2")

        // 复位
        deepChip.tap()
        webChip.tap()
        Thread.sleep(forTimeInterval: 0.3)

        let menu = app.buttons["打开对话列表"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5), "侧边栏按钮未找到")
        menu.tap()
        Thread.sleep(forTimeInterval: 0.8)
        try capture(app, name: "sidebar_v2")

        let settingsEntry = app.buttons["打开设置"]
        XCTAssertTrue(settingsEntry.waitForExistence(timeout: 5), "设置入口未找到")
        settingsEntry.tap()
        Thread.sleep(forTimeInterval: 0.8)
        try capture(app, name: "settings_v2")

        let accountRow = app.buttons["账号管理"]
        XCTAssertTrue(accountRow.waitForExistence(timeout: 5), "账号管理入口未找到")
        accountRow.tap()
        Thread.sleep(forTimeInterval: 0.8)
        try capture(app, name: "api_config_v2")
    }

    /// 验证输入框内的 + 展开拍照/相册/文件，再点收起
    func testAttachmentToggle() throws {
        let app = XCUIApplication()
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        XCTAssertFalse(app.buttons["拍照"].exists, "默认应收起附件区")
        let expand = app.buttons["展开附件"]
        XCTAssertTrue(expand.waitForExistence(timeout: 5), "展开按钮未找到")
        expand.tap()
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertTrue(app.buttons["拍照"].exists, "点击 + 后应显示拍照")
        XCTAssertTrue(app.buttons["相册"].exists, "点击 + 后应显示相册")
        XCTAssertTrue(app.buttons["文件"].exists, "点击 + 后应显示文件")
        try capture(app, name: "attachments_expanded")

        app.buttons["收起附件"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertFalse(app.buttons["拍照"].exists, "再次点击应收起附件区")
    }

    /// 真实验证：点击输入框弹出键盘后，点击输入框以外区域应收起键盘
    func testKeyboardDismissOnOutsideTap() throws {
        let app = XCUIApplication()
        app.launch()
        Thread.sleep(forTimeInterval: 1.0)

        let input = app.textFields["发消息或按住说话"]
        XCTAssertTrue(input.waitForExistence(timeout: 5), "输入框未找到")
        input.tap()
        input.typeText("测试键盘收起")
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertEqual(input.value as? String, "测试键盘收起", "文字输入失败")
        XCTAssertTrue(app.keyboards.count > 0, "点击输入框后键盘应弹出")
        try capture(app, name: "keyboard_shown")

        // 点击中央问候语（输入框以外区域）
        let greeting = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '好'")).firstMatch
        XCTAssertTrue(greeting.exists, "问候语未找到")
        greeting.tap()
        Thread.sleep(forTimeInterval: 0.6)

        XCTAssertEqual(app.keyboards.count, 0, "点击输入框以外区域后键盘应收起")
        XCTAssertEqual(input.value as? String, "测试键盘收起", "收键盘不应清空输入")
        try capture(app, name: "keyboard_dismissed")
    }

    private func capture(_ app: XCUIApplication, name: String) throws {
        let url = URL(fileURLWithPath: "/tmp/deepseek_\(name).png")
        try app.screenshot().image.pngData()?.write(to: url)
    }
}

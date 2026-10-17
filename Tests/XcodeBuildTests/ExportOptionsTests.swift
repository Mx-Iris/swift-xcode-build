import Foundation
import System
import Testing
import XcodeBuild

@Suite struct `Export options` {
    static let everyOption: ExportOptions = {
        var options = ExportOptions(method: .releaseTesting)
        options.destination = .export
        options.teamIdentifier = "ABCDE12345"
        options.signingStyle = .manual
        options.signingCertificate = "Apple Distribution"
        options.installerSigningCertificate = "Developer ID Installer"
        options.provisioningProfiles = ["com.example.app": "Release Testing Profile"]
        options.distributionBundleIdentifier = "com.example.app"
        options.iCloudContainerEnvironment = .production
        options.manageAppVersionAndBuildNumber = false
        options.generateAppStoreInformation = true
        options.uploadSymbols = false
        options.stripSwiftSymbols = true
        options.testFlightInternalTestingOnly = true
        options.thinning = .device(modelIdentifier: "iPhone7,1")
        options.manifest = DistributionManifest(
            appURL: "https://example.com/App.ipa",
            displayImageURL: "https://example.com/small.png",
            fullSizeImageURL: "https://example.com/large.png",
            assetPackManifestURL: "https://example.com/assets.plist"
        )
        options.embedOnDemandResourcesAssetPacksInBundle = false
        options.onDemandResourcesAssetPacksBaseURL = "https://example.com/assets"
        return options
    }()

    static func propertyList(of options: ExportOptions) throws -> [String: Any] {
        let data = Data(try options.propertyList())
        // `format:` is an optional pointer; passing nil is safe.
        let propertyList = try unsafe PropertyListSerialization.propertyList(from: data, format: nil)
        return try #require(propertyList as? [String: Any])
    }

    @Test func `every option is written under the key xcodebuild documents`() throws {
        let propertyList = try Self.propertyList(of: Self.everyOption)

        #expect(propertyList["method"] as? String == "release-testing")
        #expect(propertyList["destination"] as? String == "export")
        #expect(propertyList["teamID"] as? String == "ABCDE12345")
        #expect(propertyList["signingStyle"] as? String == "manual")
        #expect(propertyList["signingCertificate"] as? String == "Apple Distribution")
        #expect(propertyList["installerSigningCertificate"] as? String == "Developer ID Installer")
        #expect(propertyList["provisioningProfiles"] as? [String: String] == ["com.example.app": "Release Testing Profile"])
        #expect(propertyList["distributionBundleIdentifier"] as? String == "com.example.app")
        #expect(propertyList["iCloudContainerEnvironment"] as? String == "Production")
        #expect(propertyList["manageAppVersionAndBuildNumber"] as? Bool == false)
        #expect(propertyList["generateAppStoreInformation"] as? Bool == true)
        #expect(propertyList["uploadSymbols"] as? Bool == false)
        #expect(propertyList["stripSwiftSymbols"] as? Bool == true)
        #expect(propertyList["testFlightInternalTestingOnly"] as? Bool == true)
        #expect(propertyList["thinning"] as? String == "iPhone7,1")
        #expect(propertyList["manifest"] as? [String: String] == [
            "appURL": "https://example.com/App.ipa",
            "displayImageURL": "https://example.com/small.png",
            "fullSizeImageURL": "https://example.com/large.png",
            "assetPackManifestURL": "https://example.com/assets.plist",
        ])
        #expect(propertyList["embedOnDemandResourcesAssetPacksInBundle"] as? Bool == false)
        #expect(propertyList["onDemandResourcesAssetPacksBaseURL"] as? String == "https://example.com/assets")
        #expect(propertyList.count == 18)
    }

    @Test func `options left unset are left out`() throws {
        let propertyList = try Self.propertyList(of: ExportOptions(method: .developerID))
        #expect(propertyList.keys.sorted() == ["method"])
    }

    @Test func `thinning names its special values the way xcodebuild spells them`() {
        #expect(AppThinning.universal.rawValue == "<none>")
        #expect(AppThinning.allVariants.rawValue == "<thin-for-all-variants>")
    }
}

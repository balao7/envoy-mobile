import Foundation

/// Builder used for creating new instances of EnvoyClient.
@objcMembers
public final class EnvoyClientBuilder: NSObject {
  private let base: BaseConfiguration
  private var engineType: EnvoyEngine.Type = EnvoyEngineImpl.self
  private var logLevel: LogLevel = .info

  private enum BaseConfiguration {
    case yaml(String)
    case domain(String)
  }

  private var connectTimeoutSeconds: UInt32 = 30
  private var dnsRefreshSeconds: UInt32 = 60
  private var statsFlushSeconds: UInt32 = 60

  // MARK: - Public

  /// Initialize a new builder with the provided domain.
  ///
  /// - parameter domain: The domain to use with Envoy (i.e., `api.foo.com`).
  ///                     TODO: https://github.com/lyft/envoy-mobile/issues/433
  public init(domain: String) {
    self.base = .domain(domain)
  }

  /// Initialize a new builder with a full YAML configuration.
  /// Setting other attributes in this builder will have no effect.
  ///
  /// - parameter yaml: Contents of a YAML file to use for configuration.
  public init(yaml: String) {
    self.base = .yaml(yaml)
  }

  /// Add a log level to use with Envoy.
  ///
  /// - parameter logLevel: The log level to use with Envoy.
  ///
  /// - returns: This builder.
  public func addLogLevel(_ logLevel: LogLevel) -> EnvoyClientBuilder {
    self.logLevel = logLevel
    return self
  }

  /// Add a timeout for new network connections to hosts in the cluster.
  ///
  /// - parameter connectTimeoutSeconds: Timeout for new network
  ///                                    connections to hosts in the cluster.
  ///
  /// - returns: This builder.
  @discardableResult
  public func addConnectTimeoutSeconds(_ connectTimeoutSeconds: UInt32)
    -> EnvoyClientBuilder
  {
    self.connectTimeoutSeconds = connectTimeoutSeconds
    return self
  }

  /// Add a rate at which to refresh DNS.
  ///
  /// - parameter dnsRefreshSeconds: Rate in seconds to refresh DNS.
  ///
  /// - returns: This builder.
  @discardableResult
  public func addDNSRefreshSeconds(_ dnsRefreshSeconds: UInt32) -> EnvoyClientBuilder {
    self.dnsRefreshSeconds = dnsRefreshSeconds
    return self
  }

  /// Add an interval at which to flush Envoy stats.
  ///
  /// - parameter statsFlushSeconds: Interval at which to flush Envoy stats.
  ///
  /// - returns: This builder.
  @discardableResult
  public func addStatsFlushSeconds(_ statsFlushSeconds: UInt32) -> EnvoyClientBuilder {
    self.statsFlushSeconds = statsFlushSeconds
    return self
  }

  /// Builds a new instance of EnvoyClient using the provided configurations.
  ///
  /// - returns: A new instance of EnvoyClient.
  public func build() throws -> EnvoyClient {
    let engine = self.engineType.init()
    switch self.base {
    case .yaml(let yaml):
      return EnvoyClient(configYAML: yaml, logLevel: self.logLevel, engine: engine)
    case .domain(let domain):
      let config = EnvoyConfiguration(domain: domain,
                                      connectTimeoutSeconds: self.connectTimeoutSeconds,
                                      dnsRefreshSeconds: self.dnsRefreshSeconds,
                                      statsFlushSeconds: self.statsFlushSeconds)
      return EnvoyClient(config: config, logLevel: self.logLevel, engine: engine)
    }
  }

  // MARK: - Internal

  /// Add a specific implementation of `EnvoyEngine` to use for starting Envoy.
  /// A new instance of this engine will be created when `build()` is called.
  /// Used for testing, as initializing with `EnvoyEngine.Type` results in a
  /// segfault: https://github.com/lyft/envoy-mobile/issues/334
  @discardableResult
  func addEngineType(_ engineType: EnvoyEngine.Type) -> EnvoyClientBuilder {
    self.engineType = engineType
    return self
  }
}

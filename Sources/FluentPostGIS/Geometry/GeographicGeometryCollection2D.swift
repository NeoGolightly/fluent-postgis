import Foundation
import PostgreSQL
import WKCodable

public struct GeographicGeometryCollection2D: Codable, Equatable, CustomStringConvertible, PostgreSQLDataConvertible  {
   
    /// The points
    public let geometries: [AnyGeometryConvertible]

    /// Create a new `GISGeographicGeometryCollection2D`
    public init(geometries: [AnyGeometryConvertible]) {
        self.geometries = geometries
    }
}

extension GeographicGeometryCollection2D: WKGeometryConvertible {
    /// Convertible type
    public typealias GeometryType = GeometryCollection
    
    public init(geometry: GeometryCollection) {
        geometries = geometry.geometries.map {
            if let value = $0 as? Point {
                return AnyGeometryConvertible(GeographicPoint2D(geometry: value))
            } else if let value = $0 as? LineString {
                return AnyGeometryConvertible(GeographicLineString2D(geometry: value))
            } else if let value = $0 as? WKCodable.Polygon {
                return AnyGeometryConvertible(GeographicPolygon2D(geometry: value))
            } else if let value = $0 as? MultiPoint {
                return AnyGeometryConvertible(GeographicMultiPoint2D(geometry: value))
            } else if let value = $0 as? MultiLineString {
                return AnyGeometryConvertible(GeographicMultiLineString2D(geometry: value))
            } else if let value = $0 as? MultiPolygon {
                return AnyGeometryConvertible(GeographicMultiPolygon2D(geometry: value))
            } else if let value = $0 as? GeometryCollection {
                return AnyGeometryConvertible(GeographicGeometryCollection2D(geometry: value))
            } else {
                assertionFailure()
                return AnyGeometryConvertible(GeographicPoint2D(longitude: 0, latitude: 0))
            }
        }
    }
    
    public var geometry: GeometryCollection {
        let geometries = self.geometries.map { $0.wkbGeometry }
        return .init(geometries: geometries, srid: FluentPostGISSrid)
    }
    
    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        let wkbGeometry: GeometryCollection = try WKTDecoder().decode(from: value)
        self.init(geometry: wkbGeometry)
    }
    
    public func encode(to encoder: Encoder) throws {
        let wktEncoder = WKTEncoder()
        let value = wktEncoder.encode(geometry)
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public static func == (lhs: GeographicGeometryCollection2D, rhs: GeographicGeometryCollection2D) -> Bool {
        guard lhs.geometries.count == rhs.geometries.count else {
            return false
        }
        for i in 0..<lhs.geometries.count {
            guard lhs.geometries[i].isEqual(to: rhs.geometries[i]) else {
                return false
            }
        }
        return true
    }
}

extension GeographicGeometryCollection2D: PostgreSQLDataTypeStaticRepresentable, ReflectionDecodable {
    
    /// See `PostgreSQLDataTypeStaticRepresentable`.
    public static var postgreSQLDataType: PostgreSQLDataType { return .geographicGeometryCollection }
    
    /// See `ReflectionDecodable`.
    public static func reflectDecoded() throws -> (GeographicGeometryCollection2D, GeographicGeometryCollection2D) {
        return (.init(geometries: []),
                .init(geometries: [ AnyGeometryConvertible(GeographicPolygon2D(exteriorRing: GeographicLineString2D(points: [GeographicPoint2D(longitude: 0, latitude: 0)])))]))
    }
}

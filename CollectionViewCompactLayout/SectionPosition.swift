import Foundation
import UIKit


struct SectionAttribute {
    let initialMinY: CGFloat
    let initialMaxY: CGFloat
    let itemsCount: Int

    private let spacingHeight: CGFloat
    private let previousAggregatedVerticalOffset: CGFloat

    init(minY: CGFloat,
         maxY: CGFloat,
         itemsCount: Int,
         spacingHeight: CGFloat,
         previousAggregatedVerticalOffset: CGFloat
        ) {
        self.initialMinY = minY
        self.initialMaxY = maxY
        self.itemsCount = itemsCount
        self.spacingHeight = spacingHeight
        self.previousAggregatedVerticalOffset = previousAggregatedVerticalOffset
    }

    static func emptySectionPosition(previousAggregatedVerticalOffset: CGFloat) -> SectionAttribute {
        return SectionAttribute(minY: .nan,
                               maxY: .nan,
                               itemsCount: 0,
                               spacingHeight: 0,
                               previousAggregatedVerticalOffset: previousAggregatedVerticalOffset)
    }

    var hasItems: Bool { return itemsCount > 0 }

    var aggregatedVerticalOffset: CGFloat {
        return previousAggregatedVerticalOffset + spacingHeight
    }

    var decorationViewMinY: CGFloat {
        return initialMinY + previousAggregatedVerticalOffset
    }

    var newMinY: CGFloat {
        return initialMinY + aggregatedVerticalOffset
    }

    var newMaxY: CGFloat {
        return initialMaxY + aggregatedVerticalOffset
    }
}

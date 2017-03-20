import Foundation
import UIKit


struct SectionAttribute {
    let initialMinY: CGFloat
    let initialMaxY: CGFloat
    let itemsCount: Int

    private let spacingHeight: CGFloat
    private let previousAggregatedVerticalOffset: CGFloat

    init(initialMinY: CGFloat,
         initialMaxY: CGFloat,
         itemsCount: Int,
         spacingHeight: CGFloat,
         previousAggregatedVerticalOffset: CGFloat
        ) {
        self.initialMinY = initialMinY
        self.initialMaxY = initialMaxY
        self.itemsCount = itemsCount
        self.spacingHeight = spacingHeight
        self.previousAggregatedVerticalOffset = previousAggregatedVerticalOffset
    }

    static func empty(previousAggregatedVerticalOffset: CGFloat,
                      sectionTopHeight: CGFloat,
                      sectionBottomHeight: CGFloat) -> SectionAttribute {
        let verticalOffsetMinusHeaderFooter = previousAggregatedVerticalOffset - sectionTopHeight - sectionBottomHeight
        return SectionAttribute(initialMinY: .nan,
                                initialMaxY: .nan,
                                itemsCount: 0,
                                spacingHeight: 0,
                                previousAggregatedVerticalOffset: verticalOffsetMinusHeaderFooter)
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

import Foundation
import UIKit
import SDWebImage

public enum ImageScrollIndicatorStyle{
    case pageControlBelow, pageControlOverContext, arrowControlBelow, none
}

public class FLImageScrollView: UIView{
    
    fileprivate let pageControl = UIPageControl()
    fileprivate var displayingImageViewList: [FLAnimatedImageView] = []
    
    private let scrollView = UIScrollView()
    private let arrowControlView = UIView()
    private let leftArrow = UIButton()
    private let rightArrow = UIButton()
    private let numberLabel = UILabel()
    
    private let pageControlHeight: CGFloat = 20
    private let arrowControlHeight: CGFloat = 30
    private let arrowControlViewWidth: CGFloat = 140
    
    private var displayingCaptionLabelList: [UILabel] = []
    private var minImageRatio: CGFloat = 2
    
    private let captionLabelTopPadding: CGFloat = 10
    
    
    // Public values
    
    public private(set) var hasCaption = false
    
    public var indicatorControlTopPadding: CGFloat = 5
    public var captionLabelHeight: CGFloat = 0
    public var indicatorAreaHeight: CGFloat = 0
    public var pageControlOffsetFromBottom: CGFloat = 30
    
    public var enableEncodeURL = false
    
    public var leftArrowImage: UIImage?{
        didSet{
            leftArrow.setImage(leftArrowImage, for: UIControlState.normal)
        }
    }
    
    public var rightArrowImage: UIImage?{
        didSet{
            rightArrow.setImage(rightArrowImage, for: .normal)
        }
    }
    
    // Better for large number of galleries or large photos
    public var loadVisibleOnly = false
    
    public var currentPage: Int{
        return pageControl.currentPage
    }
    
    public var imageList: [String] = []{
        didSet{
            
            updateScrollViewContent()
        }
    }
    
    public var captionList: [String] = []{
        didSet{
            updateControlHeight()
        }
    }
    
    public var indicatorStyle: ImageScrollIndicatorStyle = .pageControlBelow{
        didSet{
            
            if indicatorStyle != oldValue {
                updateControlHeight()
            }
        }
    }
    
    public var imageContentMode: UIViewContentMode = .scaleAspectFit{
        didSet{
            
            updateScrollViewContent()
        }
    }
    
    public var pageControlpageIndicatorTintColor = UIColor(white: 0.9, alpha: 0.8){
        didSet{
            
            updatePageControl()
        }
    }
    
    public var pageControlcurrentPageIndicatorTintColor = UIColor(white: 0.2, alpha: 0.8){
        didSet{
            
            updatePageControl()
        }
    }
    
    public var isPagingEnabled = true {
        didSet{
            
            self.scrollView.isPagingEnabled = self.isPagingEnabled
        }
    }
    
    public var isSnapEnabled = false
    
    public var imageWidth: CGFloat? {
        didSet{
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    public var imageMargin: CGFloat = 0 {
        didSet{
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    public var imageSpacing: CGFloat = 0 {
        didSet{
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    public private(set) var lastTouchIndex: Int = 0
    public private(set) var beginScrollContentX: CGFloat = 0
    
    init(){
        super.init(frame:CGRect.zero)
        defaultConfiguration()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        defaultConfiguration()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        defaultConfiguration()
    }
    
    private func defaultConfiguration(){
        
        scrollView.backgroundColor = UIColor.clear
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.canCancelContentTouches = true
        scrollView.delegate = self
        
        updatePageControl()
        
        let leftArrowSelector = #selector(FLImageScrollView.leftArrowTapped(sender:))
        let rightArrowSelector = #selector(FLImageScrollView.rightArrowTapped(sender:))
        
        leftArrow.setImage(UIImage(named: "gallery_arrow_left"), for: .normal)
        leftArrow.addTarget(self, action: leftArrowSelector, for: .touchUpInside)
        leftArrow.contentMode = .scaleAspectFit
        
        rightArrow.setImage(UIImage(named: "gallery_arrow_right"), for: .normal)
        rightArrow.addTarget(self, action: rightArrowSelector, for: .touchUpInside)
        rightArrow.contentMode = .scaleAspectFit
        
        numberLabel.textAlignment = .center
        numberLabel.font = UIFont.systemFont(ofSize: 14)
        numberLabel.textColor = UIColor.gray
        
        addSubview(scrollView)
        addSubview(pageControl)
        addSubview(arrowControlView)
        
        arrowControlView.addSubview(leftArrow)
        arrowControlView.addSubview(rightArrow)
        arrowControlView.addSubview(numberLabel)
        
        updateScrollViewContent()
    }
    
    private func updatePageControl(){
        
        pageControl.hidesForSinglePage = true
        pageControl.isUserInteractionEnabled = false
        pageControl.pageIndicatorTintColor = pageControlpageIndicatorTintColor
        pageControl.currentPageIndicatorTintColor = pageControlcurrentPageIndicatorTintColor
    }
    
    public func updateControlHeight(){
        
        indicatorAreaHeight = 0
        captionLabelHeight = 0
        
        if self.captionList.count > 0{
            hasCaption = true
        }
        
        if indicatorStyle == .none {
            
            pageControl.isHidden = true
            arrowControlView.isHidden = true
            
        } else if indicatorStyle == .pageControlBelow{
            
            pageControl.isHidden = false
            arrowControlView.isHidden = true
            
            if imageList.count > 1{
                indicatorAreaHeight += indicatorControlTopPadding + pageControlHeight
            }
            
        }else if indicatorStyle == .pageControlOverContext{
            
            arrowControlView.isHidden = true
            pageControl.isHidden = false
            
        }else{
            
            pageControl.isHidden = true
            arrowControlView.isHidden = false
            
            if imageList.count > 1{
                indicatorAreaHeight += indicatorControlTopPadding + arrowControlHeight
            }
        }
        
        if imageList.count <= 1{
            
            pageControl.isHidden = true
            arrowControlView.isHidden = true
        }
        
        for (index, _) in self.imageList.enumerated(){
            
            if self.captionList.count > index{
                
                let caption = self.captionList[index]
                
                if caption.count > 0{
                    
                    let constraintRect = CGSize(width: bounds.width - 20, height: CGFloat.greatestFiniteMagnitude)
                    
                    let boundingBox = caption.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)], context: nil)
                    
                    captionLabelHeight = max(boundingBox.height, captionLabelHeight - self.captionLabelTopPadding) + self.captionLabelTopPadding
                }
            }
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateControlHeight()
        
        let imageWidth: CGFloat = self.imageWidth ?? self.scrollView.bounds.width
        let imageListCount: CGFloat = CGFloat(imageList.count)
        let scrollViewContentWidth: CGFloat = imageListCount * imageWidth + (imageListCount) * imageSpacing + imageMargin * 2 - imageSpacing
        
        if indicatorStyle == .none {
            
            scrollView.contentSize = CGSize(width: scrollViewContentWidth, height: bounds.height)
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            
        } else if indicatorStyle == .pageControlBelow{
            
            scrollView.contentSize = CGSize(width: scrollViewContentWidth, height: bounds.height - indicatorAreaHeight)
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - indicatorAreaHeight)
            
            pageControl.center = scrollView.center
            pageControl.frame = CGRect(x: pageControl.frame.origin.x, y: bounds.height - pageControlHeight, width: pageControl.bounds.width, height: pageControlHeight)
            
        }else if indicatorStyle == .pageControlOverContext{
            
            scrollView.contentSize = CGSize(width: scrollViewContentWidth, height: bounds.height)
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            
            pageControl.center = scrollView.center
            pageControl.frame = CGRect(x:pageControl.frame.origin.x, y: scrollView.bounds.height - captionLabelHeight - pageControlOffsetFromBottom, width: pageControl.bounds.width, height: pageControlHeight)
            
        }else if indicatorStyle == .arrowControlBelow{
            
            scrollView.contentSize = CGSize(width: scrollViewContentWidth, height: bounds.height - indicatorAreaHeight)
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - indicatorAreaHeight)
            
            arrowControlView.center = scrollView.center
            arrowControlView.frame = CGRect(x: arrowControlView.frame.origin.x, y: bounds.height - arrowControlHeight, width: arrowControlViewWidth, height: arrowControlHeight)
            
            leftArrow.frame = CGRect(x: 0, y: 0, width: arrowControlHeight, height: arrowControlHeight)
            rightArrow.frame = CGRect(x: arrowControlView.frame.width - arrowControlHeight, y: 0, width: arrowControlHeight, height: arrowControlHeight)
            numberLabel.frame = CGRect(x: arrowControlHeight, y: 0, width: arrowControlView.frame.width - arrowControlHeight * 2, height: arrowControlHeight)
        }
        
        if bounds.height > 1 {
            for (index, imageView) in displayingImageViewList.enumerated(){
                
                let indexFloat = CGFloat(index)
                
                UIView.performWithoutAnimation {
                    
                    imageView.frame = CGRect(x: self.imageMargin + indexFloat * imageWidth + CGFloat(index) * self.imageSpacing, y: 0, width: imageWidth, height: self.scrollView.bounds.height - self.captionLabelHeight)
                    
                    if self.hasCaption{
                        
                        let captionLabel = self.displayingCaptionLabelList[index]
                        
                        captionLabel.preferredMaxLayoutWidth = imageWidth
                        captionLabel.frame.origin = CGPoint(x: imageView.frame.origin.x, y: imageView.bounds.height + self.captionLabelTopPadding)
                        captionLabel.sizeToFit()
                        captionLabel.frame.size = CGSize(width: imageWidth, height: self.captionLabelHeight - self.captionLabelTopPadding)
                        captionLabel.sizeToFit()
                    }
                }
            }
        }
    }
    
    private func updateScrollViewContent(){
        
        pageControl.numberOfPages = imageList.count
        
        updateNumberLabel()
        
        while displayingImageViewList.count < imageList.count{
            
            let imageView = FLAnimatedImageView()
            scrollView.addSubview(imageView)
            displayingImageViewList.append(imageView)
            
            if hasCaption{
                let captionLabel = UILabel()
                
                captionLabel.textColor = UIColor.gray
                captionLabel.font = UIFont.systemFont(ofSize: 14)
                captionLabel.numberOfLines = 0
                
                scrollView.addSubview(captionLabel)
                displayingCaptionLabelList.append(captionLabel)
            }
        }
        
        while displayingImageViewList.count > imageList.count{
            displayingImageViewList.removeLast()
            
            if hasCaption{
                displayingCaptionLabelList.removeLast()
            }
        }
        
        for imageView in displayingImageViewList{
            imageView.contentMode = imageContentMode
        }
        
        if loadVisibleOnly{
            
            loadVisibleImages()
            
        }else{
            
            for (index, _) in imageList.enumerated(){
                
                loadImageForIndex(index: index)
            }
        }
        
        for (index, caption) in captionList.enumerated(){
            
            if hasCaption && displayingCaptionLabelList.count > index && captionList.count > index{
                
                let captionLabel = displayingCaptionLabelList[index]
                captionLabel.text = caption
            }
        }
        
        if displayingImageViewList.count > 0{
            let imageView = displayingImageViewList[currentPage]
            scrollView.bringSubview(toFront: imageView)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    @objc func leftArrowTapped(sender: AnyObject){
        
        if pageControl.currentPage > 0{
            
            let imageWidth: CGFloat = self.imageWidth ?? self.scrollView.bounds.width
            scrollView.setContentOffset(CGPoint(x: imageMargin + CGFloat(pageControl.currentPage - 1) * (imageWidth + imageSpacing) - (self.scrollView.bounds.width - imageWidth) / 2, y: 0), animated: true)
            loadVisibleImages()
        }
    }
    
    @objc func rightArrowTapped(sender: AnyObject){
        
        if pageControl.currentPage + 1 < pageControl.numberOfPages{
            
            let imageWidth: CGFloat = self.imageWidth ?? self.scrollView.bounds.width
            
            scrollView.setContentOffset(CGPoint(x: imageMargin + CGFloat(pageControl.currentPage + 1) * (imageWidth + imageSpacing) - (self.scrollView.bounds.width - imageWidth) / 2, y: 0), animated: true)
            loadVisibleImages()
        }
    }
    
    fileprivate func updateNumberLabel(){
        
        numberLabel.text = "\(pageControl.currentPage + 1) / \(imageList.count)"
    }
    
    public func setLongPressGesture(target: AnyObject?, action: Selector){
        
        for imageView in self.displayingImageViewList{
            
            let gesture = UILongPressGestureRecognizer(target: target, action: action)
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(gesture)
        }
    }
    
    public func setInternalScrollViewUserInteractionEnabled(isUserInteractionEnabled: Bool){
        
        self.scrollView.isUserInteractionEnabled = isUserInteractionEnabled
    }
    
    public func getInternalScrollViewPanGesture() -> UIPanGestureRecognizer{
        
        return self.scrollView.panGestureRecognizer
    }
    
    fileprivate func loadVisibleImages(){
        
        guard loadVisibleOnly else {
            
            return
        }
        
        for (imageIndex, imageView) in self.displayingImageViewList.enumerated(){
            
            if self.shouldLoadCurrentIndex(index: imageIndex){
                
                if displayingImageViewList[imageIndex].image == nil{
                    
                    loadImageForIndex(index: imageIndex)
                }
                
            }else if imageView.image != nil {
                
                imageView.image = nil
            }
        }
    }
    
    private func shouldLoadCurrentIndex(index: Int) -> Bool{
        
        var contentBox = CGRect.zero
        contentBox.origin = self.scrollView.contentOffset
        contentBox.size = self.scrollView.contentSize
        
        return self.displayingImageViewList[index].frame.intersects(contentBox)
    }
    
    private func loadImageForIndex(index: Int){
        
        var imageString = imageList[index]
        
        if let encodedString = imageString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed), enableEncodeURL{
            
            imageString = encodedString
        }
        
        if let url = URL(string: imageString){
            
            let imageView = displayingImageViewList[index]
            
            imageView.sd_setShowActivityIndicatorView(true)
            imageView.sd_setIndicatorStyle(.gray)
            
            imageView.sd_setImage(with: url, placeholderImage: nil, options: [SDWebImageOptions.avoidAutoSetImage], progress: nil, completed: { (image, error, cacheType, url) in
                
                imageView.image = image
                
                if let _ = error, image == nil{
                    
                    imageView.image = UIImage(named: "broken_image")
                    
                }else if cacheType != SDImageCacheType.memory {
                    
                    imageView.alpha = 0
                }else{
                    
                }
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    imageView.alpha = 1
                })
                
                self.layoutIfNeeded()
            })
        }
    }
    
    public func setCurrentImagePage(index: Int) {
        
        let imageWidth: CGFloat = self.imageWidth ?? self.scrollView.bounds.width
        
        if index == 0 {
            
            scrollView.setContentOffset(CGPoint(x: CGFloat(index) * (imageWidth + imageSpacing), y: 0), animated: true)
            
        } else if index == self.imageList.count - 1 {
            
            scrollView.setContentOffset(CGPoint(x: scrollView.contentSize.width - self.scrollView.bounds.width, y: 0), animated: true)
            
        } else {
            
            scrollView.setContentOffset(CGPoint(x: imageMargin + CGFloat(index) * (imageWidth + imageSpacing) - (self.scrollView.bounds.width - imageWidth) / 2, y: 0), animated: true)
        }
        
        loadVisibleImages()
    }
    
    public func imageView(for index: Int) -> FLAnimatedImageView? {
        
        if self.displayingImageViewList.count > index {
            
            return self.displayingImageViewList[index]
        }
        
        return nil
    }
    
    public func sourceView() -> UIView{
        
        return self.displayingImageViewList[currentPage]
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let touch = touches.first {
            
            let location = touch.location(in: self)
            
            let contentWidth = scrollView.contentSize.width - imageMargin * 2
            let imageWidth = contentWidth / CGFloat(self.displayingImageViewList.count)
            let currentIndex = Int((scrollView.contentOffset.x + location.x - imageMargin) / imageWidth)
            
            self.lastTouchIndex = currentIndex
        }
    }
}

//MARK: - UIScrollViewDelegate

extension FLImageScrollView: UIScrollViewDelegate{
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        beginScrollContentX = scrollView.contentOffset.x
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let width = self.imageWidth ?? scrollView.bounds.width;
        let wholePage = Int((scrollView.contentOffset.x + (0.5 * width)) / width);
        
        if pageControl.currentPage != wholePage{
            
            pageControl.currentPage = wholePage
            
            updateNumberLabel()
            
            let imageView = displayingImageViewList[pageControl.currentPage]
            
            scrollView.bringSubview(toFront: imageView)
        }
        
        loadVisibleImages()
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if !isPagingEnabled && isSnapEnabled {
            
            let width: CGFloat = self.imageWidth ?? self.scrollView.bounds.width
            let wholePage = Int((targetContentOffset.pointee.x + (0.5 * width)) / width);
            
            switch targetContentOffset.pointee.x {
            case let targetX where targetX <= 0.0: break
            case let targetX where targetX >= scrollView.contentSize.width - self.scrollView.bounds.width: break
            default:
                
                targetContentOffset.pointee.x = imageMargin + CGFloat(wholePage) * (width + imageSpacing) - (self.scrollView.bounds.width - width) / 2
            }
        }
    }
}


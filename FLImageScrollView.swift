import Foundation
import SDWebImage

public enum ImageScrollIndicatorStyle{
    case pageControlBelow, pageControlOverContext, arrowControlBelow
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
            updateControlHeight()
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
        
        if indicatorStyle == .pageControlBelow{
            
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
                
                if caption.characters.count > 0{
                    
                    let constraintRect = CGSize(width: bounds.width - 20, height: CGFloat.greatestFiniteMagnitude)
                    
                    let boundingBox = caption.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14)], context: nil)
                    
                    captionLabelHeight = max(boundingBox.height, captionLabelHeight - self.captionLabelTopPadding) + self.captionLabelTopPadding
                }
            }
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateControlHeight()
        
        if indicatorStyle == .pageControlBelow{
            
            scrollView.contentSize = CGSize(width: CGFloat(imageList.count) * bounds.width, height: bounds.height - indicatorAreaHeight)
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - indicatorAreaHeight)
            
            pageControl.center = scrollView.center
            pageControl.frame = CGRect(x: pageControl.frame.origin.x, y: bounds.height - pageControlHeight, width: pageControl.bounds.width, height: pageControlHeight)
            
        }else if indicatorStyle == .pageControlOverContext{
            
            scrollView.contentSize = CGSize(width: CGFloat(imageList.count) * bounds.width, height: bounds.height)
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            
            pageControl.center = scrollView.center
            pageControl.frame = CGRect(x:pageControl.frame.origin.x, y: scrollView.bounds.height - captionLabelHeight - pageControlOffsetFromBottom, width: pageControl.bounds.width, height: pageControlHeight)
        }else if indicatorStyle == .arrowControlBelow{
            
            scrollView.contentSize = CGSize(width: CGFloat(imageList.count) * bounds.width, height: bounds.height - indicatorAreaHeight)
            scrollView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - indicatorAreaHeight)
            
            arrowControlView.center = scrollView.center
            arrowControlView.frame = CGRect(x: arrowControlView.frame.origin.x, y: bounds.height - arrowControlHeight, width: arrowControlViewWidth, height: arrowControlHeight)
            
            leftArrow.frame = CGRect(x: 0, y: 0, width: arrowControlHeight, height: arrowControlHeight)
            rightArrow.frame = CGRect(x: arrowControlView.frame.width - arrowControlHeight, y: 0, width: arrowControlHeight, height: arrowControlHeight)
            numberLabel.frame = CGRect(x: arrowControlHeight, y: 0, width: arrowControlView.frame.width - arrowControlHeight * 2, height: arrowControlHeight)
        }
        
        
        for (index, imageView) in displayingImageViewList.enumerated(){
            
            let indexFloat = CGFloat(index)
            
            imageView.frame = CGRect(x: indexFloat * self.scrollView.bounds.width, y: 0, width: self.scrollView.bounds.width, height: self.scrollView.bounds.height - captionLabelHeight)
            
            if hasCaption{
                
                let captionLabel = displayingCaptionLabelList[index]
                captionLabel.frame = CGRect(x: indexFloat * self.scrollView.bounds.width + 10, y: imageView.bounds.height + self.captionLabelTopPadding, width: self.scrollView.bounds.width - 20, height: captionLabelHeight - self.captionLabelTopPadding)
                
                captionLabel.sizeToFit()
            }
        }
        
        scrollView.scrollRectToVisible(CGRect(x: CGFloat(pageControl.currentPage) * scrollView.bounds.width, y: 0, width: scrollView.bounds.width, height: 1), animated: false)
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
    
    func leftArrowTapped(sender: AnyObject){
        
        if pageControl.currentPage > 0{
            
            scrollView.setContentOffset(CGPoint(x: CGFloat(pageControl.currentPage - 1) * scrollView.bounds.width, y: 0), animated: true)
            loadVisibleImages()
        }
    }
    
    func rightArrowTapped(sender: AnyObject){
        
        if pageControl.currentPage + 1 < pageControl.numberOfPages{
            
            scrollView.setContentOffset(CGPoint(x: CGFloat(pageControl.currentPage + 1) * scrollView.bounds.width, y: 0), animated: true)
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
        
        if loadVisibleOnly{
            
            for (imageIndex, imageView) in self.displayingImageViewList.enumerated(){
                
                if self.shouldLoadCurrentIndex(index: imageIndex){
                    
                    if displayingImageViewList[imageIndex].image == nil{
                        loadImageForIndex(index: imageIndex)
                    }
                }else{
                    
                    imageView.image = nil
                }
            }
        }
    }
    
    private func shouldLoadCurrentIndex(index: Int) -> Bool{
        
        return index == pageControl.currentPage || index == pageControl.currentPage + 1 || index == pageControl.currentPage - 1
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
            imageView.sd_setImage(with: url, placeholderImage: nil, options: [], progress: nil, completed: { (image, error, cacheType, url) in
                
                if let _ = error, image == nil{
                    imageView.image = UIImage(named: "broken_image")
                    
                }else if cacheType != SDImageCacheType.memory {
                    
                    imageView.alpha = 0
                }
                
                UIView.animate(withDuration: 0.3, animations: {
                    
                    imageView.alpha = 1
                })
                
                self.layoutIfNeeded()
            })
        }
    }
}

//MARK: - UIScrollViewDelegate

extension FLImageScrollView: UIScrollViewDelegate{
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let width = scrollView.frame.size.width;
        let wholePage = Int((scrollView.contentOffset.x + (0.5 * width)) / width);
        
        if pageControl.currentPage != wholePage{
            
            pageControl.currentPage = wholePage
            
            updateNumberLabel()
            loadVisibleImages()
            
            let imageView = displayingImageViewList[pageControl.currentPage]
            
            scrollView.bringSubview(toFront: imageView)
        }
    }
}

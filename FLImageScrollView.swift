import Foundation
import SDWebImage

class ScrollView: UIScrollView{
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.superview?.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.superview?.touchesMoved(touches, withEvent: event)
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.superview?.touchesCancelled(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.superview?.touchesEnded(touches, withEvent: event)
    }
}

public enum ImageScrollIndicatorStyle{
    case pageControlBelow, pageControlOverContext, arrowControlBelow
}

public class FLImageScrollView: UIView{
    
    private let scrollView = ScrollView()
    private let pageControl = UIPageControl()
    private let arrowControlView = UIView()
    private let leftArrow = UIButton()
    private let rightArrow = UIButton()
    private let numberLabel = UILabel()
    
    private let pageControlHeight: CGFloat = 20
    private let arrowControlHeight: CGFloat = 30
    private let arrowControlViewWidth: CGFloat = 140
    
    private var displayingImageViewList: [UIImageView] = []
    private var displayingCaptionLabelList: [UILabel] = []
    private var minImageRatio: CGFloat = 2
    
    private let captionLabelTopPadding: CGFloat = 10
    
    // Public values
    
    private(set) var hasCaption = false
    
    public var indicatorControlTopPadding: CGFloat = 5
    public var captionLabelHeight: CGFloat = 0
    public var indicatorAreaHeight: CGFloat = 0
    public var pageControlOffsetFromBottom: CGFloat = 30
    
    public var enableEncodeURL = false
    
    var leftArrowImage: UIImage?{
        didSet{
            leftArrow.setImage(leftArrowImage, forState: UIControlState.Normal)
        }
    }
    
    var rightArrowImage: UIImage?{
        didSet{
            rightArrow.setImage(rightArrowImage, forState: UIControlState.Normal)
        }
    }
    
    // Better for large number of galleries or large photos
    var loadVisibleOnly = false
    
    var currentPage: Int{
        get{
            return pageControl.currentPage
        }
    }
    
    var imageList: [String] = []{
        didSet{
            updateScrollViewContent()
        }
    }
    
    var captionList: [String] = []{
        didSet{
            updateControlHeight()
        }
    }
    
    var indicatorStyle: ImageScrollIndicatorStyle = .pageControlBelow{
        didSet{
            updateControlHeight()
        }
    }
    
    var imageContentMode: UIViewContentMode = UIViewContentMode.ScaleAspectFit{
        didSet{
            updateScrollViewContent()
        }
    }
    
    var pageControlpageIndicatorTintColor = UIColor(white: 0.9, alpha: 0.8){
        didSet{
            
            updatePageControl()
        }
    }
    
    var pageControlcurrentPageIndicatorTintColor = UIColor(white: 0.2, alpha: 0.8){
        didSet{
            
            updatePageControl()
        }
    }
    
    
    init(){
        super.init(frame:CGRectZero)
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
        
        //                backgroundColor = UIColor.purpleColor()
        //                leftArrow.backgroundColor = UIColor.greenColor()
        //                rightArrow.backgroundColor = UIColor.greenColor()
        //                arrowControlView.backgroundColor = UIColor.yellowColor()
        //                pageControl.backgroundColor = UIColor.yellowColor()
        
        
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        
        updatePageControl()
        
        let leftArrowSelector = #selector(FLImageScrollView.leftArrowTapped(_:))
        let rightArrowSelector = #selector(FLImageScrollView.rightArrowTapped(_:))
        
        leftArrow.setImage(UIImage(named: "gallery_arrow_left"), forState: UIControlState.Normal)
        leftArrow.addTarget(self, action: leftArrowSelector, forControlEvents: UIControlEvents.TouchUpInside)
        leftArrow.contentMode = UIViewContentMode.ScaleAspectFit
        
        rightArrow.setImage(UIImage(named: "gallery_arrow_right"), forState: UIControlState.Normal)
        rightArrow.addTarget(self, action: rightArrowSelector, forControlEvents: UIControlEvents.TouchUpInside)
        rightArrow.contentMode = UIViewContentMode.ScaleAspectFit
        
        numberLabel.textAlignment = NSTextAlignment.Center
        numberLabel.font = UIFont.systemFontOfSize(14)
        
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
        pageControl.userInteractionEnabled = false
        pageControl.pageIndicatorTintColor = pageControlpageIndicatorTintColor
        pageControl.currentPageIndicatorTintColor = pageControlcurrentPageIndicatorTintColor
    }
    
    private func updateControlHeight(){
        
        indicatorAreaHeight = 0
        captionLabelHeight = 0
        
        if self.captionList.count > 0{
            hasCaption = true
        }
        
        if indicatorStyle == .pageControlBelow{
            
            pageControl.hidden = false
            arrowControlView.hidden = true
            
            if imageList.count > 1{
                indicatorAreaHeight += indicatorControlTopPadding + pageControlHeight
            }
            
            
        }else if indicatorStyle == .pageControlOverContext{
            
            arrowControlView.hidden = true
            pageControl.hidden = false
            
        }else{
            
            pageControl.hidden = true
            arrowControlView.hidden = false
            
            if imageList.count > 1{
                indicatorAreaHeight += indicatorControlTopPadding + arrowControlHeight
            }
        }
        
        if imageList.count <= 1{
            
            pageControl.hidden = true
            arrowControlView.hidden = true
        }
        
        for (index, _) in self.imageList.enumerate(){
            
            if self.captionList.count > index{
                
                let caption = self.captionList[index]
                
                if caption.characters.count > 0{
                    
                    let constraintRect = CGSize(width: bounds.width - 20, height: CGFloat.max)
                    
                    let boundingBox = caption.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14)], context: nil)
                    
                    captionLabelHeight = max(boundingBox.height, captionLabelHeight - self.captionLabelTopPadding) + self.captionLabelTopPadding
                }
            }
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateControlHeight()
        
        if indicatorStyle == .pageControlBelow{
            
            scrollView.contentSize = CGSizeMake(CGFloat(imageList.count) * bounds.width, bounds.height - indicatorAreaHeight)
            scrollView.frame = CGRectMake(0, 0, bounds.width, bounds.height - indicatorAreaHeight)
            
            pageControl.center = scrollView.center
            pageControl.frame = CGRectMake(pageControl.frame.origin.x, bounds.height - pageControlHeight, pageControl.bounds.width, pageControlHeight)
            
        }else if indicatorStyle == .pageControlOverContext{
            
            scrollView.contentSize = CGSizeMake(CGFloat(imageList.count) * bounds.width, bounds.height)
            scrollView.frame = CGRectMake(0, 0, bounds.width, bounds.height)
            
            pageControl.center = scrollView.center
            pageControl.frame = CGRectMake(pageControl.frame.origin.x, scrollView.bounds.height - captionLabelHeight - pageControlOffsetFromBottom, pageControl.bounds.width, pageControlHeight)
        }else if indicatorStyle == .arrowControlBelow{
            
            scrollView.contentSize = CGSizeMake(CGFloat(imageList.count) * bounds.width, bounds.height - indicatorAreaHeight)
            scrollView.frame = CGRectMake(0, 0, bounds.width, bounds.height - indicatorAreaHeight)
            
            arrowControlView.center = scrollView.center
            arrowControlView.frame = CGRectMake(arrowControlView.frame.origin.x, bounds.height - arrowControlHeight, arrowControlViewWidth, arrowControlHeight)
            
            leftArrow.frame = CGRectMake(0, 0, arrowControlHeight, arrowControlHeight)
            rightArrow.frame = CGRectMake(arrowControlView.frame.width - arrowControlHeight, 0, arrowControlHeight, arrowControlHeight)
            numberLabel.frame = CGRectMake(arrowControlHeight, 0, arrowControlView.frame.width - arrowControlHeight * 2, arrowControlHeight)
        }
        
        
        for (index, imageView) in displayingImageViewList.enumerate(){
            
            let indexFloat = CGFloat(index)
            
            imageView.frame = CGRectMake(indexFloat * self.scrollView.bounds.width, 0, self.scrollView.bounds.width, self.scrollView.bounds.height - captionLabelHeight)
            
            if hasCaption{
                
                let captionLabel = displayingCaptionLabelList[index]
                captionLabel.frame = CGRectMake(indexFloat * self.scrollView.bounds.width + 10, imageView.bounds.height + self.captionLabelTopPadding, self.scrollView.bounds.width - 20, captionLabelHeight - self.captionLabelTopPadding)
                
                captionLabel.sizeToFit()
            }
        }
        
        scrollView.scrollRectToVisible(CGRectMake(CGFloat(pageControl.currentPage) * scrollView.bounds.width, 0,  scrollView.bounds.width, 1), animated: false)
    }
    
    private func updateScrollViewContent(){
        
        pageControl.numberOfPages = imageList.count
        
        updateNumberLabel()
        
        while displayingImageViewList.count < imageList.count{
            let imageView = UIImageView()
            
            scrollView.addSubview(imageView)
            displayingImageViewList.append(imageView)
            
            if hasCaption{
                let captionLabel = UILabel()
                
                captionLabel.textColor = UIColor.grayColor()
                captionLabel.font = UIFont.systemFontOfSize(14)
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
            
            for (index, _) in imageList.enumerate(){
                
                loadImageForIndex(index)
            }
        }
        
        for (index, caption) in captionList.enumerate(){
            
            if hasCaption && displayingCaptionLabelList.count > index && captionList.count > index{
                
                let captionLabel = displayingCaptionLabelList[index]
                captionLabel.text = caption
            }
        }
        
        if displayingImageViewList.count > 0{
            let imageView = displayingImageViewList[currentPage]
            scrollView.bringSubviewToFront(imageView)
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
    
    private func updateNumberLabel(){
        
        numberLabel.text = "\(pageControl.currentPage + 1) / \(imageList.count)"
    }
    
    private func setLongPressGesture(target: AnyObject?, action: Selector){
        
        for imageView in self.displayingImageViewList{
            
            let gesture = UILongPressGestureRecognizer(target: target, action: action)
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(gesture)
        }
    }
    
    private func loadVisibleImages(){
        
        if loadVisibleOnly{
            
            for (imageIndex, imageView) in self.displayingImageViewList.enumerate(){
                
                if self.shouldLoadCurrentIndex(imageIndex){
                    
                    if displayingImageViewList[imageIndex].image == nil{
                        loadImageForIndex(imageIndex)
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
        
        if let encodedString = imageString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) where enableEncodeURL{
            
            imageString = encodedString
        }
        
        if let url = NSURL(string: imageString){
            
            let imageView = displayingImageViewList[index]
            imageView.sd_setImageWithURL(url, placeholderImage: UIImage(named: "broken_image"), completed: nil)
        }
    }
}

//MARK: - UIScrollViewDelegate

extension FLImageScrollView: UIScrollViewDelegate{
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let width = scrollView.frame.size.width;
        let wholePage = Int((scrollView.contentOffset.x + (0.5 * width)) / width);
        
        if pageControl.currentPage != wholePage{
            
            pageControl.currentPage = wholePage
            
            updateNumberLabel()
            loadVisibleImages()
            
            let imageView = displayingImageViewList[pageControl.currentPage]
            
            scrollView.bringSubviewToFront(imageView)
        }
    }
}


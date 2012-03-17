//
//  ColorFunctions.h
//  SceneDesigner
//

static inline NSString *NSStringFromColor(ccColor3B color)
{
    return [NSString stringWithFormat:@"{%u, %u, %u}", color.r, color.g, color.b];
}

static inline ccColor3B ColorFromNSString(NSString *string)
{
    ccColor3B color;
    sscanf([string cStringUsingEncoding:NSUTF8StringEncoding], "{%u, %u, %u}", &color.r, &color.g, &color.b);
    return color;
}

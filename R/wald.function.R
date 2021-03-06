wald.function <- function (data, chi.res.hist, ks.res.hist) {
log.dist.wald <- function (r, par) {
  a <- par[1] ## location parameter, mean
  b <- par[2] ## scale parameter
  fwald <- (sqrt(b)/sqrt(8 * (pi^3) * (r^5))) * exp(-(b * ((r - a)^2))/(2 * (a^2) * r))
  -sum(log(fwald)) ##
}
dist.wald <- function (r, a, b) {
  fwald <- 2*pi*r * (sqrt(b)/sqrt(8 * (pi^3) * (r^5))) * exp(-(b * ((r - a)^2))/(2 * (a^2) * r))
}
# initial values estimation
m <- mean(data)
scale <- length(data)/(sum(1/data)-mean(1/data))
# optimization procedure
dist.wald.opt <- optim (par = c(m, scale), ##
                        fn = log.dist.wald, ##
                        r = data, ##
                        method = "Nelder-Mead",
                        # lower = c(0.00001, 0.00001), ## parameters minimum values
                        control = list(maxit = 10000))
# output values
# AIC
aic.wald <- 2*length(dist.wald.opt$par) + 2 * dist.wald.opt$value
# AICc
aicc.wald <- aic.wald + (2 * length(dist.wald.opt$par)^2 + 2 * length(dist.wald.opt$par))/(length(data) - length(dist.wald.opt$par) - 1 )
# BIC
bic.wald <-  2 * dist.wald.opt$value + length(dist.wald.opt$par)*log(length(data))
# Chi-squared
chi.expected.values.wald <- dist.wald(chi.res.hist$mids, dist.wald.opt$par[1], dist.wald.opt$par[2])*length(data)*(chi.res.hist$breaks[2] - chi.res.hist$breaks[1])
chi.squared.statistic.wald <- sum((chi.res.hist$counts - chi.expected.values.wald)^2 / chi.expected.values.wald)
chi.squared.pvalue.wald <- 1-pchisq(chi.squared.statistic.wald, length(chi.res.hist$counts)-3)
# Kolmogorov-Smirnov
ks.expected.values.wald <- dist.wald(ks.res.hist$mids, dist.wald.opt$par[1], dist.wald.opt$par[2])*length(data)*(ks.res.hist$breaks[2] - ks.res.hist$breaks[1])
simul.wald <- c()
for (i in seq_along(ks.res.hist$mids)) {
  simul.wald <- c(simul.wald, rep(ks.res.hist$mids[i], round(ks.expected.values.wald[i], 0)))
}
ks.wald <- ks.test(data, simul.wald)
g.max.wald <- as.numeric(ks.wald$statistic)
KS.wald <- as.numeric(ks.wald$p.value)

# cumulative.expected.values.wald <- c(expected.values.wald[1])
# for (i in 1+seq_along(expected.values.wald)) {
#   cumulative.expected.values.wald[i] <- cumulative.expected.values.wald[i-1] + expected.values.wald[i]
# }
# cumulative.expected.values.wald <- cumulative.expected.values.wald/sum(expected.values.wald)
# cumulative.expected.values.wald <- cumulative.expected.values.wald[!is.na(cumulative.expected.values.wald)]
# g.max.wald <- max(abs(cumulative.data - cumulative.expected.values.wald))
# if (g.max.wald < (sqrt(-log(0.01/2)/(2*length(cumulative.data))) * (1/(2*length(cumulative.data))))) {
#   KS.wald <- "Accept"
# } else {KS.wald <- "Reject"}
# parameter estimate
par.1.wald <- dist.wald.opt$par[1]
par.2.wald <- dist.wald.opt$par[2]
# parameter estimate standard error
par.1.se.wald <- sqrt(diag(solve(numDeriv::hessian(log.dist.wald, x=dist.wald.opt$par, r=data))))[1]
par.2.se.wald <- sqrt(diag(solve(numDeriv::hessian(log.dist.wald, x=dist.wald.opt$par, r=data))))[2]
# mean dispersal distance
mean.wald <- dist.wald.opt$par[1]
mean.stderr.wald <- par.1.se.wald
# variance
variance.wald <- dist.wald.opt$par[1]^3/dist.wald.opt$par[2]
variance.stderr.wald <- msm::deltamethod(~ x1^3/x2, mean = dist.wald.opt$par, cov = solve(numDeriv::hessian(log.dist.wald, x=dist.wald.opt$par, r=data)) )
# skewness
skewness.wald <- 3 * sqrt((dist.wald.opt$par[1]*dist.wald.opt$par[2]))
skewness.stderr.wald <- msm::deltamethod(~ 3 * sqrt((x1*x2)), mean = dist.wald.opt$par, cov = solve(numDeriv::hessian(log.dist.wald, x=dist.wald.opt$par, r=data)) )
# kurtosis
kurtosis.wald <- (15*dist.wald.opt$par[1])/dist.wald.opt$par[2]
kurtosis.stderr.wald <- msm::deltamethod(~ (15*x1)/x2, mean = dist.wald.opt$par, cov = solve(numDeriv::hessian(log.dist.wald, x=dist.wald.opt$par, r=data)) )
# output
res <- data.frame(aic.wald, aicc.wald, bic.wald,
                          chi.squared.statistic.wald, chi.squared.pvalue.wald,g.max.wald, KS.wald,
                          par.1.wald, par.1.se.wald, par.2.wald, par.2.se.wald,
                          mean.wald, mean.stderr.wald, variance.wald, variance.stderr.wald,
                          skewness.wald, skewness.stderr.wald, kurtosis.wald, kurtosis.stderr.wald)
wald.values <- list("opt" = dist.wald.opt, "res" = res)
}
